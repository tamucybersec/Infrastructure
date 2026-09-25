terraform {
  required_version = ">= 1.6"

  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.22"
    }
  }

  backend "pg" {}
}
