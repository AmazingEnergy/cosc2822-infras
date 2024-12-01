#!/bin/sh

# remember to change permission
# chmod 700 get-started.sh

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY

export AWS_DEFAULT_PROFILE=$1

mkdir ./_output
mkdir ./_output/run-cfn
OUTPUT_DIR="./_output/run-cfn"

CFN_STACK_NAME=$2
CFN_OUTPUT_KEY=$3
SAVE_FILE=$4

# Create and download a key pair using AWS CloudFormation
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/create-key-pairs.html#create-key-pair-cloudformation

# AWS CLI Filter output
# https://docs.aws.amazon.com/cli/v1/userguide/cli-usage-filter.html
# https://jmespath.org/specification.html#filterexpressions

# https://docs.aws.amazon.com/cli/latest/reference/cloudformation/describe-stacks.html
CFN_OUTPUT_VALUE=$(aws cloudformation describe-stacks \
	--stack-name $CFN_STACK_NAME \
	--query "Stacks[0].Outputs[?OutputKey=='$CFN_OUTPUT_KEY'] | [0].OutputValue" \
	--output text)

if [[ -n "$CFN_OUTPUT_VALUE" && ! "$CFN_OUTPUT_VALUE" == "None" ]]; then
  echo "CloudFormation Stack Output Name:'NewKeyPairId' Value:'$CFN_OUTPUT_VALUE'"

	SSM_PARAMETER_NAME="/ec2/keypair/$CFN_OUTPUT_VALUE"
	echo "Download key pair at $SSM_PARAMETER_NAME"

	chmod 600 $OUTPUT_DIR/$SAVE_FILE

	# https://docs.aws.amazon.com/cli/latest/reference/ssm/get-parameter.html
	aws ssm get-parameter \
		--name $SSM_PARAMETER_NAME \
		--with-decryption \
		--query Parameter.Value \
		--output text > $OUTPUT_DIR/$SAVE_FILE

	echo "Key pair downloaded at $OUTPUT_DIR/$SAVE_FILE"
	echo ""
else
	echo "CloudFormation Stack Output Name:'NewKeyPairId' is not found"
	echo ""
fi