#!/bin/sh
set -eu

# TF_MODE=apply (default): init + apply every stack, migrating legacy local
#   state into postgres on first run.
# TF_MODE=plan: read-only preview for CI. Validates and plans every stack
#   against the real state without locking, applying, or migrating.
mode="${TF_MODE:-apply}"

# State backend: base postgres database, one schema per stack.
export PGPASSWORD="$POSTGRES_PASSWORD"
export PG_CONN_STR="host=${PG_HOST:-postgres} user=$POSTGRES_USER dbname=$POSTGRES_DB sslmode=disable"

status=0
for dir in /work/stacks/*/; do
  name=$(basename "$dir")
  echo "==> stack: $name ($mode)"
  (
    cd "$dir"
    [ -f env.sh ] && . ./env.sh
    terraform init -input=false -reconfigure -backend-config="schema_name=tf_$name"

    if [ "$mode" = plan ]; then
      terraform validate
      # -lock=false: a preview must never block (or be blocked by) a real apply.
      terraform plan -input=false -lock=false -no-color
      exit 0
    fi

    # One-time migration from the old local backend.
    old="/state/$name.tfstate"
    if [ -f "$old" ] && [ -z "$(terraform state list)" ]; then
      echo "migrating $old into postgres backend"
      terraform state push "$old"
      mv "$old" "$old.migrated"
    fi

    terraform apply -input=false -auto-approve
  ) || status=1
done
exit $status
