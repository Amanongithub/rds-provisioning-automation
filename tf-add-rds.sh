#!/usr/bin/env bash

set -e

echo
echo "=========================================="
echo "          RDS Provisioning Tool"
echo "=========================================="
echo

# --------------------------------------------------
# Check required commands
# --------------------------------------------------

if ! command -v terraform >/dev/null 2>&1; then
    echo "ERROR: Terraform is not installed or not in PATH."
    exit 1
fi

if ! command -v git >/dev/null 2>&1; then
    echo "ERROR: Git is not installed or not in PATH."
    exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
    echo "ERROR: GitHub CLI (gh) is not installed or not in PATH."
    exit 1
fi

# --------------------------------------------------
# Check Git repository
# --------------------------------------------------

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "ERROR: This directory is not a Git repository."
    exit 1
fi

# --------------------------------------------------
# RDS name
# --------------------------------------------------

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

# --------------------------------------------------
# RDS instance size
# --------------------------------------------------

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
    echo "Created Terraform file:"
    echo "$TERRAFORM_FILE"

else

    echo
    echo "Existing Terraform file found:"
    echo "$TERRAFORM_FILE"

fi

# --------------------------------------------------
# Prevent duplicate RDS
# --------------------------------------------------

if grep -q "resource \"aws_db_instance\" \"$RDS_NAME\"" "$TERRAFORM_FILE"; then
    echo
    echo "ERROR: RDS '$RDS_NAME' already exists."
    echo "Terraform configuration was not changed."
    exit 1
fi

# --------------------------------------------------
# Append RDS Terraform resource
# --------------------------------------------------

cat >> "$TERRAFORM_FILE" <<EOF

resource "aws_db_instance" "$RDS_NAME" {
  identifier          = "$RDS_NAME"
  engine              = "postgres"
  engine_version      = "16"
  instance_class      = "$INSTANCE_CLASS"
  allocated_storage   = 20
  storage_type        = "gp3"
  deletion_protection = $DELETION_PROTECTION
  skip_final_snapshot = true
  publicly_accessible = false

  tags = {
    Name        = "$RDS_NAME"
    Environment = "$ENVIRONMENT"
    ManagedBy   = "Terraform"
  }
}
EOF

echo
echo "Terraform configuration added."

# --------------------------------------------------
# Terraform format
# --------------------------------------------------

echo
echo "Running terraform fmt..."

terraform fmt "$TERRAFORM_FILE"

echo "Terraform formatting completed."

# --------------------------------------------------
# Terraform validation
# --------------------------------------------------

echo
echo "Running terraform validate..."

terraform -chdir=terraform validate

echo
echo "Terraform validation: PASSED"

# --------------------------------------------------
# Git branch
# --------------------------------------------------

BRANCH_NAME="rds/$RDS_NAME"

echo
echo "=========================================="
echo "Creating Git branch"
echo "=========================================="
echo
echo "Branch: $BRANCH_NAME"

# Make sure we are starting from main

git checkout main

# Update local main

git pull origin main

# Create new RDS branch

git checkout -b "$BRANCH_NAME"

echo
echo "Branch created successfully:"
echo "$BRANCH_NAME"

# --------------------------------------------------
# Git add
# --------------------------------------------------

echo
echo "Adding changes to Git..."

# Add this script and Terraform/configuration changes
git add "$0"
git add terraform/rds.tf
git add "$OUTPUT_FILE"

# --------------------------------------------------
# Check changes
# --------------------------------------------------

if git diff --cached --quiet; then
    echo
    echo "ERROR: No changes detected."
    exit 1
fi

# --------------------------------------------------
# Git commit
# --------------------------------------------------

echo
echo "Creating Git commit..."

git commit -m "Add RDS: $RDS_NAME"

# --------------------------------------------------
# Push branch
# --------------------------------------------------

echo
echo "Pushing branch to GitHub..."

git push -u origin "$BRANCH_NAME"

echo
echo "Branch pushed successfully."

# --------------------------------------------------
# Create Pull Request
# --------------------------------------------------

echo
echo "=========================================="
echo "Creating Pull Request"
echo "=========================================="
echo

PR_URL="$(
    gh pr create \
        --base main \
        --head "$BRANCH_NAME" \
        --title "Add RDS: $RDS_NAME" \
        --body "## RDS Configuration

- RDS Name: $RDS_NAME
- Environment: $ENVIRONMENT
- Instance Class: $INSTANCE_CLASS
- Deletion Protection: $DELETION_PROTECTION
- Engine: PostgreSQL 16
- Terraform validation: PASSED

Terraform apply was NOT executed."
)"

# --------------------------------------------------
# Final result
# --------------------------------------------------

echo
echo "=========================================="
echo "              SUCCESS"
echo "=========================================="
echo
echo "RDS name             : $RDS_NAME"
echo "Environment          : $ENVIRONMENT"
echo "Instance class       : $INSTANCE_CLASS"
echo "Deletion protection  : $DELETION_PROTECTION"
echo
echo "Terraform validation : PASSED"
echo "Git branch           : $BRANCH_NAME"
echo
echo "Pull Request:"
echo "$PR_URL"
echo
echo "Terraform apply was NOT executed."
echo