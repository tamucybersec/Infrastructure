export TF_VAR_pg_username="$POSTGRES_USER"
export TF_VAR_pg_password="$POSTGRES_PASSWORD"

# Build the per-service database map from <SVC>_POSTGRES_{USER,PASSWORD,DB} envs
TF_VAR_databases=$(jq -cn '
  [ $ENV | keys[] | capture("^(?<svc>[A-Z0-9]+)_POSTGRES_USER$").svc ]
  | map({
      key: ascii_downcase,
      value: {
        user:     $ENV[. + "_POSTGRES_USER"],
        password: $ENV[. + "_POSTGRES_PASSWORD"],
        db:       $ENV[. + "_POSTGRES_DB"]
      }
    })
  | from_entries
')
export TF_VAR_databases
