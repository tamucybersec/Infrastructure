export TF_VAR_pg_username="$POSTGRES_USER"
export TF_VAR_pg_password="$POSTGRES_PASSWORD"

# build terraform maps from envs
export TF_VAR_databases=$(jq -cn '
  env
  | [keys[] 
  | select(test("^[A-Z0-9]+_POSTGRES_USER$")) 
  | sub("_POSTGRES_USER$"; "")] as $svcs
  | [$svcs[] as $s 
  | {
      key: ($s | ascii_downcase),
      value: {
        user:     env[$s + "_POSTGRES_USER"],
        password: env[$s + "_POSTGRES_PASSWORD"],
        db:       env[$s + "_POSTGRES_DB"]
      }
    }]
  | from_entries')
