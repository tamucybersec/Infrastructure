provider "postgresql" {
  host     = var.pg_host
  port     = var.pg_port
  username = var.pg_username
  password = var.pg_password
  sslmode  = "disable"
}

locals {
  services = toset(nonsensitive(keys(var.databases)))
}

resource "postgresql_role" "this" {
  for_each = local.services

  name     = var.databases[each.key].user
  password = var.databases[each.key].password
  login    = true
}

resource "postgresql_database" "this" {
  for_each = local.services

  name  = var.databases[each.key].db
  owner = postgresql_role.this[each.key].name
}
