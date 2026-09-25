variable "pg_host" {
  type    = string
  default = "postgres"
}

variable "pg_port" {
  type    = number
  default = 5432
}

variable "pg_username" {
  type = string
}

variable "pg_password" {
  type      = string
  sensitive = true
}

# One role + one database per service, keyed by service name.
# Populated from <SERVICE>_POSTGRES_{USER,PASSWORD,DB} by env.sh.
variable "databases" {
  type = map(object({
    user     = string
    password = string
    db       = string
  }))
  sensitive = true
}
