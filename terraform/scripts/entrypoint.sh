#!/bin/sh
set -eu

# TF_MODE=apply (default): init + apply the saved plan of every stack (from
#   /plans, written by CI), migrating legacy local state into postgres first.
#   Stacks with no saved plan are skipped.
# TF_MODE=plan: preview for CI. Validates and plans every stack against the
#   real state without locking, applying, or migrating, and saves each plan
#   to /plans/<stack>.tfplan for a later apply.
mode="${TF_MODE:-apply}"

# Plain output in plan mode: it gets pasted into PR comments, not a terminal.
[ "$mode" = plan ] && export TF_CLI_ARGS="-no-color"

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
      terraform plan -input=false -lock=false -no-color -out="/plans/$name.tfplan"
      exit 0
    fi

    # One-time migration from the old local backend.
    old="/state/$name.tfstate"
    if [ -f "$old" ] && [ -z "$(terraform state list)" ]; then
      echo "migrating $old into postgres backend"
      terraform state push "$old"
      mv "$old" "$old.migrated"
    fi

    plan="/plans/$name.tfplan"
    if [ ! -f "$plan" ]; then
      echo "no saved plan for $name, skipping"
      exit 0
    fi
    terraform apply -input=false "$plan"
    rm -f "$plan"
  ) || status=1
done
exit $status
