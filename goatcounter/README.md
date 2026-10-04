# GoatCounter hosting

GoatCounter 2.7.0 provides private website analytics for the club. The root Compose file runs it on the shared `infra` network with a dedicated SQLite volume, plus a daily backup service. Traffic remains separate from CyberHam's membership data. This draft does not create DNS, TLS, API credentials, or a public nginx virtual host automatically.

## Provision and deploy

Run all commands from the Infrastructure repository root using `scripts/compose.sh`.

1. Choose the analytics hostname (examples below use `analytics.cybr.club`). Confirm its DNS and coverage by the existing origin certificate. Adapt `goatcounter/nginx.conf.example` and copy it into `nginx/confs/analytics.cybr.club.conf`. Confirm nginx restores the visitor IP from trusted upstream proxies/Cloudflare before forwarding it: the example deliberately overwrites untrusted forwarding headers, but `$remote_addr` is otherwise only the direct peer. Do not expose GoatCounter's port directly on the host.
2. Decrypt the infrastructure secrets through the existing SOPS workflow, then initialize the database and first account. Replace the hostname and officer email; the command prompts for the password:

   ```sh
   scripts/decrypt.sh .
   scripts/compose.sh run --rm goatcounter db create site -db=sqlite+/home/goatcounter/goatcounter-data/db.sqlite3 -createdb -vhost=analytics.cybr.club -user.email=officer@example.com
   scripts/compose.sh up -d goatcounter goatcounter-backup
   scripts/compose.sh exec nginx nginx -t
   scripts/compose.sh exec nginx nginx -s reload
   ```

3. Sign in to the selected hostname, keep statistics private and public visitor counters disabled, and set the API user's timezone to UTC. Create an API token with **read statistics only** under Settings → API; do not grant count, export, or site-management access.
4. Supply `GOATCOUNTER_URL=https://analytics.cybr.club` and `GOATCOUNTER_API_TOKEN=<statistics token>` to the process running CyberHam's Compose deployment. Its Compose file consumes these environment variables. Keep the token in the established encrypted SOPS storage. One compatible path is the runner's existing encrypted `.env`: decrypt it and manually recreate the runner so its deployment jobs inherit the variables. Coordinate that restart outside the runner's own job. Alternatively, explicitly load a dedicated decrypted env file in CyberHam's deployment workflow. Merely adding an encrypted file does not wire it into CyberHam. Never put the token in website build variables.
5. Recreate CyberHam with those variables available. Set the website repository's GitHub Actions variable `NEXT_PUBLIC_GOATCOUNTER_URL` to the same HTTPS origin and rebuild/deploy the website. Use the virtual hostname, because GoatCounter selects a site using the HTTP Host header.

The current Infrastructure workflows do not automatically deploy GoatCounter; use the explicit commands above. See the [website analytics guide](https://github.com/tamucybersec/cybr.club/blob/main/docs/analytics.md) for campaign links, QR downloads, reporting, and frontend configuration.

## Persistent storage and backups

`goatcounter_data` holds the live SQLite database; `goatcounter_backups` holds consistent snapshots. The backup service uses SQLite's online backup API, includes committed WAL writes, checks integrity, retries failures after five minutes, and retains 30 days of snapshots. Do not use `down -v` during routine maintenance.

Monitor backup logs and snapshot age (alert after 26 hours). Arrange daily copies to off-host storage: the local snapshot volume does not protect against host loss. Off-host backup transport and monitoring are not provided by this change.

Before an update, make and export a snapshot:

```sh
scripts/compose.sh run --rm goatcounter-backup python /backup.py --once
mkdir -p analytics-backups
scripts/compose.sh cp goatcounter-backup:/backups/. ./analytics-backups/
```

Keep exports outside Git. For recovery, stop both services, retain the damaged volume for investigation, and restore a verified snapshot as `/home/goatcounter/goatcounter-data/db.sqlite3` in a fresh data volume. Match the pinned image's user/group ownership, and ensure no stale `-wal` or `-shm` files accompany the restored database. Start GoatCounter, verify its reports, then start backups and test a new snapshot. Practice recovery on an isolated stack first.

The `-automigrate` flag applies database migrations on startup. Upgrade only after reviewing release notes and copying a pre-upgrade backup off-host. Rollback requires both the previous image and its matching database snapshot. Review releases periodically and rotate exposed API tokens.

## Validation

```sh
python3 goatcounter/test_backup.py
scripts/compose.sh config -q
```

Compose validation requires the existing infrastructure secrets. The backup tests cover live WAL recovery, integrity, file permissions, and a missing source database.

After deployment, visit a tagged QR link, click Join and Learn More, and confirm campaign visits/clicks in Admin → Analytics after counts persist. Verify officer permissions, the unavailable-report state when GoatCounter stops, and backup restoration. If a CSP is configured, allow the analytics origin in `script-src`, `connect-src`, and `img-src` for `/count.js` and `/count`.

References: [GoatCounter API](https://www.goatcounter.com/api.html), [GoatCounter v2.7.0](https://github.com/arp242/goatcounter/releases/tag/v2.7.0).
