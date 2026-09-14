#!/usr/bin/env bash

set -e

echo
echo "=========================================="
echo "          RDS Provisioning Tool"
echo "=========================================="
echo

read -r -p "RDS name: " RDS_NAME

RDS_NAME="$(
    printf '%s' "$RDS_NAME" |
    tr '[:upper:]' '[:lower:]' |
    tr -cd 'a-z0-9-'
)"

if [[ -z "$RDS_NAME" ]]; then
    echo "ERROR: RDS name cannot be empty."
    exit 1
fi

echo
echo "Select RDS instance size:"
echo
echo "1) db.t3.micro"
echo "2) db.t3.small"
echo "3) db.t3.medium"
echo "4) db.r6g.large"
echo "5) db.r6g.xlarge"
echo

read -r -p "Choice [1-5]: " SIZE

case "$SIZE" in
    1) INSTANCE_CLASS="db.t3.micro" ;;
    2) INSTANCE_CLASS="db.t3.small" ;;
    3) INSTANCE_CLASS="db.t3.medium" ;;
    4) INSTANCE_CLASS="db.r6g.large" ;;
    5) INSTANCE_CLASS="db.r6g.xlarge" ;;
    *)
        echo "ERROR: Invalid size."
        exit 1
        ;;
esac

# --------------------------------------------------
# Detect environment
# --------------------------------------------------

if [[ "$RDS_NAME" == *prod* ]]; then
    ENVIRONMENT="prod"
    DELETION_PROTECTION=true
else
    ENVIRONMENT="non-prod"
    DELETION_PROTECTION=false
fi

# --------------------------------------------------
# Display configuration
# --------------------------------------------------

echo
echo "=========================================="
echo "RDS Configuration"
echo "=========================================="
echo
echo "Name                : $RDS_NAME"
echo "Instance class      : $INSTANCE_CLASS"
echo "Environment         : $ENVIRONMENT"
echo "Deletion protection : $DELETION_PROTECTION"
echo

if [[ "$DELETION_PROTECTION" == true ]]; then
    echo "WARNING: Production RDS detected."
    echo "Deletion protection has been automatically enabled."
    echo
fi

read -r -p "Create RDS configuration? [y/N]: " CONFIRM

if [[ ! "${CONFIRM:-n}" =~ ^[yY]$ ]]; then
    echo
    echo "Cancelled."
    exit 0
fi

# --------------------------------------------------
# Create directories
# --------------------------------------------------

mkdir -p output
mkdir -p terraform

# --------------------------------------------------
# Create configuration file
# --------------------------------------------------

OUTPUT_FILE="output/${RDS_NAME}.conf"

cat > "$OUTPUT_FILE" <<EOF
RDS_NAME=$RDS_NAME
ENVIRONMENT=$ENVIRONMENT
INSTANCE_CLASS=$INSTANCE_CLASS
DELETION_PROTECTION=$DELETION_PROTECTION
ENGINE=postgres
ENGINE_VERSION=16
ALLOCATED_STORAGE=20
STORAGE_TYPE=gp3
EOF

echo
echo "Configuration file created:"
echo "$OUTPUT_FILE"

# --------------------------------------------------
# Terraform file
# --------------------------------------------------

TERRAFORM_FILE="terraform/rds.tf"

# Create Terraform provider configuration
if [[ ! -f "$TERRAFORM_FILE" ]]; then

    cat > "$TERRAFORM_FILE" <<EOF
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

EOF

    echo
    echo "Created new Terraform file:"
    echo "$TERRAFORM_FILE"

else

    echo
    echo "Existing Terraform file found:"
    echo "$TERRAFORM_FILE"

fi

# --------------------------------------------------
# Prevent duplicate RDS resource
# --------------------------------------------------

if grep -q "resource \"aws_db_instance\" \"$RDS_NAME\"" "$TERRAFORM_FILE"; then
    echo
    echo "ERROR: RDS '$RDS_NAME' already exists in $TERRAFORM_FILE."
    echo "Terraform configuration was not appended."
    exit 1
fi

# --------------------------------------------------
# Append RDS resource
# --------------------------------------------------

cat >> "$TERRAFORM_FILE" <<EOF

resource "aws_db_instance" "$RDS_NAME" {
  identifier              = "$RDS_NAME"
  engine                  = "postgres"
  engine_version          = "16"
  instance_class          = "$INSTANCE_CLASS"
  allocated_storage       = 20
  storage_type            = "gp3"
  deletion_protection     = $DELETION_PROTECTION
  skip_final_snapshot     = true
  publicly_accessible     = false

  tags = {
    Name        = "$RDS_NAME"
    Environment = "$ENVIRONMENT"
    ManagedBy   = "Terraform"
  }
}
EOF

echo
echo "Terraform configuration appended:"
echo "$TERRAFORM_FILE"

# --------------------------------------------------
# Terraform formatting
# --------------------------------------------------

echo
echo "Running terraform fmt..."

terraform fmt "$TERRAFORM_FILE"

echo "Terraform formatting completed."

# --------------------------------------------------
# Terraform initialization
# --------------------------------------------------

echo
echo "Running terraform init..."

terraform -chdir=terraform init -backend=false

echo "Terraform initialization completed."

# --------------------------------------------------
# Terraform validation
# --------------------------------------------------

echo
echo "Running terraform validate..."

terraform -chdir=terraform validate

# --------------------------------------------------
# Final result
# --------------------------------------------------

echo
echo "=========================================="
echo "SUCCESS"
echo "=========================================="
echo
echo "RDS configuration:"
echo "$OUTPUT_FILE"
echo
echo "Terraform configuration:"
echo "$TERRAFORM_FILE"
echo
echo "Terraform validation: PASSED"
echo
echo "IMPORTANT: terraform apply was NOT executed."
echo
echo "Configuration:"
echo
cat "$OUTPUT_FILE"
echo