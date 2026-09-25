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

variable "databases" {
  type = map(object({
    user     = string
    password = string
    db       = string
  }))
  sensitive = true
}
