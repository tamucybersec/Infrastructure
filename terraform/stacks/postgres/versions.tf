terraform {
  required_version = ">= 1.6"

  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.22"
    }
  }

  # State lives in the base postgres database (one schema per stack) and
  # contains secrets. entrypoint.sh supplies the connection via PG_CONN_STR /
  # PGPASSWORD and schema_name via -backend-config. The postgres server is
  # created by compose, not by this stack, so the backend is not circular.
  backend "pg" {}
}
