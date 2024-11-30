#!/bin/bash

# remember to change permission
# chmod 700 get-started.sh

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY

export AWS_DEFAULT_PROFILE="cosc2825-devops01"

echo "Set default AWS CLI profile ${AWS_DEFAULT_PROFILE}"
echo ""

mkdir ./_output
mkdir ./_output/delete-stack
OUTPUT_DIR="./_output/delete-stack"

CFN_STACK_NAME=$1

echo "Try to delete Stack:$CFN_STACK_NAME"
echo ""

# https://docs.aws.amazon.com/cli/latest/reference/cloudformation/delete-stack.html
aws cloudformation delete-stack \
	--stack-name $CFN_STACK_NAME

echo "Waiting for CloudFormation Stack $CFN_STACK_NAME to be deleted..."
echo ""
aws cloudformation wait stack-delete-complete \
	--stack-name $CFN_STACK_NAME

# https://docs.aws.amazon.com/cli/latest/reference/cloudformation/list-stacks.html#
aws cloudformation list-stacks \
	--stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE ROLLBACK_COMPLETE IMPORT_COMPLETE \
	--output json \
	> $OUTPUT_DIR/active-stacks.json

echo "List all active stacks at $OUTPUT_DIR/active-stacks.json"
echo ""

aws cloudformation list-stacks \
	--stack-status-filter DELETE_COMPLETE \
	--output json \
	> $OUTPUT_DIR/archived-stacks.json

echo "List all archived stacks at $OUTPUT_DIR/archived-stacks.json"

unset AWS_DEFAULT_PROFILE

echo ""
echo "Unset default AWS CLI profile ${AWS_DEFAULT_PROFILE}"