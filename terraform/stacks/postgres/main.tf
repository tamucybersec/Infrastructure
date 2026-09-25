provider "postgresql" {
  host     = var.pg_host
  port     = var.pg_port
  username = var.pg_username
  password = var.pg_password
  sslmode  = "disable" # traffic stays on the internal docker network
}

locals {
  databases = nonsensitive(keys(var.databases))
}

resource "postgresql_role" "this" {
  for_each = toset(local.databases)

  name            = var.databases[each.key].user
  login           = true
  password        = var.databases[each.key].password
  superuser       = false
  create_database = false
  create_role     = false
}

resource "postgresql_database" "this" {
  for_each = toset(local.databases)

  name  = var.databases[each.key].db
  owner = postgresql_role.this[each.key].name
}
