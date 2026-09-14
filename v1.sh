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

if [[ "$RDS_NAME" == *prod* ]]; then
    ENVIRONMENT="prod"
    DELETION_PROTECTION=true
else
    ENVIRONMENT="non-prod"
    DELETION_PROTECTION=false
fi

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

mkdir -p output

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
echo "=========================================="
echo "SUCCESS"
echo "=========================================="
echo
echo "RDS configuration created:"
echo "$OUTPUT_FILE"
echo
echo "Configuration:"
echo
cat "$OUTPUT_FILE"
echo