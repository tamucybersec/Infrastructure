#!/bin/sh
set -eu

mode="${TF_MODE:-apply}"
[ "$mode" = plan ] && export TF_CLI_ARGS="-no-color"

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
      terraform plan -input=false -lock=false
    else
      old="/state/$name.tfstate"
      if [ -f "$old" ] && [ -z "$(terraform state list)" ]; then
        echo "migrating $old into postgres backend"
        terraform state push "$old"
        mv "$old" "$old.backup"
      fi
      terraform apply -input=false -auto-approve
    fi
  ) || status=1
done
exit $status
