#!/bin/sh

# remember to change permission
# chmod 700 get-started.sh

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY

export AWS_DEFAULT_PROFILE=$1

echo "Set default AWS CLI profile ${AWS_DEFAULT_PROFILE}"
echo ""

CFN_STACK_NAME=$2
CFN_OUTPUT_KEY=$3

# AWS CLI Filter output
# https://docs.aws.amazon.com/cli/v1/userguide/cli-usage-filter.html
# https://jmespath.org/specification.html#filterexpressions

# https://docs.aws.amazon.com/cli/latest/reference/cloudformation/describe-stacks.html
CFN_OUTPUT_VALUE=$(aws cloudformation describe-stacks \
	--stack-name $CFN_STACK_NAME \
	--query "Stacks[0].Outputs[?OutputKey=='$CFN_OUTPUT_KEY'] | [0].OutputValue" \
	--output text)

if [[ -n "$CFN_OUTPUT_VALUE" && ! "$CFN_OUTPUT_VALUE" == "None" ]]; then
	echo $CFN_OUTPUT_VALUE
else
	echo "CloudFormation Stack Output Name:'$CFN_OUTPUT_KEY' is not found"
	exit 1
fi

unset AWS_DEFAULT_PROFILE

echo ""
echo "Unset default AWS CLI profile ${AWS_DEFAULT_PROFILE}"