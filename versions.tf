# ---------------------------------------------------------------------------
# Versões e backend de estado (repo 3 — banco gerenciado).
# Apply roda exclusivamente no GitHub Actions (branch master).
# ---------------------------------------------------------------------------
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  backend "s3" {
    bucket         = "oficina-tfstate-909314263457"
    key            = "oficina-db-infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "oficina-tflock"
    encrypt        = true
  }
}
