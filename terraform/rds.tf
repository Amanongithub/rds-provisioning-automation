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

resource "aws_db_instance" "amantest33" {
  identifier          = "amantest33"
  engine              = "postgres"
  engine_version      = "16"
  instance_class      = "db.t3.small"
  allocated_storage   = 20
  storage_type        = "gp3"
  deletion_protection = false
  skip_final_snapshot = true
  publicly_accessible = false

  tags = {
    Name        = "amantest33"
    Environment = "non-prod"
    ManagedBy   = "Terraform"
  }
}

resource "aws_db_instance" "aman44" {
  identifier          = "aman44"
  engine              = "postgres"
  engine_version      = "16"
  instance_class      = "db.r6g.large"
  allocated_storage   = 20
  storage_type        = "gp3"
  deletion_protection = false
  skip_final_snapshot = true
  publicly_accessible = false

  tags = {
    Name        = "aman44"
    Environment = "non-prod"
    ManagedBy   = "Terraform"
  }
}

resource "aws_db_instance" "testprod" {
  identifier          = "testprod"
  engine              = "postgres"
  engine_version      = "16"
  instance_class      = "db.t3.small"
  allocated_storage   = 20
  storage_type        = "gp3"
  deletion_protection = true
  skip_final_snapshot = true
  publicly_accessible = false

  tags = {
    Name        = "testprod"
    Environment = "prod"
    ManagedBy   = "Terraform"
  }
}

resource "aws_db_instance" "test55" {
  identifier          = "test55"
  engine              = "postgres"
  engine_version      = "16"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  storage_type        = "gp3"
  deletion_protection = false
  skip_final_snapshot = true
  publicly_accessible = false

  tags = {
    Name        = "test55"
    Environment = "non-prod"
    ManagedBy   = "Terraform"
  }
}

resource "aws_db_instance" "testforpr" {
  identifier          = "testforpr"
  engine              = "postgres"
  engine_version      = "16"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  storage_type        = "gp3"
  deletion_protection = false
  skip_final_snapshot = true
  publicly_accessible = false

  tags = {
    Name        = "testforpr"
    Environment = "non-prod"
    ManagedBy   = "Terraform"
  }
}

resource "aws_db_instance" "amanprodtest5" {
  identifier          = "amanprodtest5"
  engine              = "postgres"
  engine_version      = "16"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  storage_type        = "gp3"
  deletion_protection = true
  skip_final_snapshot = true
  publicly_accessible = false

  tags = {
    Name        = "amanprodtest5"
    Environment = "prod"
    ManagedBy   = "Terraform"
  }
}
