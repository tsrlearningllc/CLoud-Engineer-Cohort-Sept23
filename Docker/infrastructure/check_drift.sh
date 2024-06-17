#!/bin/bash
set -x

# Variables
AZURE_CLIENT_ID=$1
AZURE_CLIENT_SECRET=$2
AZURE_TENANT_ID=$3
SLACK_WEBHOOK_URL=$4
AZURE_SUBSCRIPTION_ID=$5
STORAGE_ACCOUNT_NAME="tsrlearningstor"
CONTAINER_NAME="terraformstate"
# TF_DIR=$8

# Set environment variables for Terraform authentication
export ARM_CLIENT_ID=$AZURE_CLIENT_ID
export ARM_CLIENT_SECRET=$AZURE_CLIENT_SECRET
export ARM_TENANT_ID=$AZURE_TENANT_ID
export ARM_SUBSCRIPTION_ID=$AZURE_SUBSCRIPTION_ID

# Log in to Azure using service principal
az login --service-principal -u "$AZURE_CLIENT_ID" -p "$AZURE_CLIENT_SECRET" --tenant "$AZURE_TENANT_ID"

# # Navigate to the Terraform directory
# cd $TF_DIR

# Initialize Terraform backend
terraform init -backend-config="storage_account_name=$STORAGE_ACCOUNT_NAME" \
               -backend-config="container_name=$CONTAINER_NAME" \
               -backend-config="key=dev.terraform.tfstate" \
               -backend-config="subscription_id=$AZURE_SUBSCRIPTION_ID"

# Run Terraform Plan
terraform plan -detailed-exitcode > plan_output.txt
PLAN_EXIT_CODE=$?

if [ $PLAN_EXIT_CODE -eq 2 ]; then
    echo "Drift detected in Terraform configuration"
    DRIFT_MESSAGE=$(cat plan_output.txt)
    # Send a notification to Slack
    PAYLOAD=$( jq -n --arg text "Drift detected in Terraform configuration:\n$DRIFT_MESSAGE" '{ text: $text }' )
    curl -X POST -H "Content-Type: application/json" -d "$PAYLOAD" "$SLACK_WEBHOOK_URL"
elif [ $PLAN_EXIT_CODE -eq 0 ]; then
    echo "No drift detected"
else
    echo "Error running terraform plan"
    exit 1
fi
