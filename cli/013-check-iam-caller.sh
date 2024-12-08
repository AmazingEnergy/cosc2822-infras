#!/bin/bash

# remember to change permission
# chmod 700 get-started.sh

mkdir ./_output
mkdir ./_output/check-iam-caller
OUTPUT_DIR="./_output/check-iam-caller"

# https://docs.aws.amazon.com/cli/latest/reference/sts/get-caller-identity.html
aws sts get-caller-identity \
	--output json \
	> $OUTPUT_DIR/current-caller.json

echo "Output details of IAM user or role at $OUTPUT_DIR/current-caller.json"
echo ""

CALLER_USER_ID=$(jq -r '.UserId' $OUTPUT_DIR/current-caller.json)
CALLER_ACCOUNT=$(jq -r '.Account' $OUTPUT_DIR/current-caller.json)
CALLER_ARN=$(jq -r '.Arn' $OUTPUT_DIR/current-caller.json)

echo "Caller has UserId: $CALLER_USER_ID under Account: $CALLER_ACCOUNT with ARN: $CALLER_ARN"
echo ""