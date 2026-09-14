terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_db_instance" "amanprod22" {
  identifier          = "amanprod22"
  engine              = "postgres"
  engine_version      = "16"
  instance_class      = "db.t3.medium"
  allocated_storage   = 20
  storage_type        = "gp3"
  deletion_protection = true
  skip_final_snapshot = true
  publicly_accessible = false

  tags = {
    Name        = "amanprod22"
    Environment = "prod"
    ManagedBy   = "Terraform"
  }
}

