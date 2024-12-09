#!/bin/bash

# remember to change permission
# chmod 700 get-started.sh

CFN_STACK_NAME=$1
CFN_STACK_REGION=${2:-"ap-southeast-1"}

mkdir ./_output
mkdir ./_output/delete-stack
mkdir ./_output/delete-stack/$CFN_STACK_NAME
OUTPUT_DIR="./_output/delete-stack/$CFN_STACK_NAME"

echo "Try to delete Stack:$CFN_STACK_NAME"
echo ""

# https://docs.aws.amazon.com/cli/latest/reference/cloudformation/delete-stack.html
aws cloudformation delete-stack \
	--stack-name $CFN_STACK_NAME \
	--region $CFN_STACK_REGION

echo "Waiting for CloudFormation Stack $CFN_STACK_NAME to be deleted..."
echo ""
aws cloudformation wait stack-delete-complete \
	--stack-name $CFN_STACK_NAME \
	--region $CFN_STACK_REGION

# https://docs.aws.amazon.com/cli/latest/reference/cloudformation/list-stacks.html#
aws cloudformation list-stacks \
	--stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE ROLLBACK_COMPLETE IMPORT_COMPLETE \
	--region $CFN_STACK_REGION \
	--output json \
	> $OUTPUT_DIR/active-stacks.json

echo "List all active stacks at $OUTPUT_DIR/active-stacks.json"
echo ""

aws cloudformation list-stacks \
	--stack-status-filter DELETE_COMPLETE \
	--region $CFN_STACK_REGION \
	--output json \
	> $OUTPUT_DIR/archived-stacks.json

echo "List all archived stacks at $OUTPUT_DIR/archived-stacks.json"