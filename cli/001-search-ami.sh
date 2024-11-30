#!/bin/sh

# remember to change permission
# chmod 700 get-started.sh

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY

export AWS_DEFAULT_PROFILE="cosc2825-devops01"

echo "Set default AWS CLI profile ${AWS_DEFAULT_PROFILE}"
echo ""

mkdir ./_output
mkdir ./_output/launch-instance
OUTPUT_DIR="./_output/launch-instance"

YEAR=$(date "+%Y")
MONTH=$(date "+%m")
LAST_MONTH=$((MONTH - 1))
AMI_CREATED_THIS_MONTH="$YEAR-$MONTH-01"
AMI_CREATED_LAST_MONTH="$YEAR-$LAST_MONTH-01"

echo "Search for latest built free-tier AMI (created after $AMI_CREATED_THIS_MONTH or $AMI_CREATED_LAST_MONTH)"
echo ""

# finding ami https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/finding-an-ami.html
# describe-images https://awscli.amazonaws.com/v2/documentation/api/latest/reference/ec2/describe-images.html

aws ec2 describe-images \
	--owners amazon \
	--filters "Name=architecture,Values=x86_64" \
	"Name=is-public,Values=true" \
	"Name=image-type,Values=machine" \
	"Name=name,Values=amzn2-ami-kernel-*-hvm-*" \
	"Name=state,Values=available" \
	"Name=root-device-type,Values=ebs" \
	--query "Images[?CreationDate>'$AMI_CREATED_THIS_MONTH' || CreationDate>'$AMI_CREATED_LAST_MONTH'] | reverse(sort_by(@, &CreationDate))" \
	> $OUTPUT_DIR/amis.json 

# AWS CLI filter output
# https://docs.aws.amazon.com/cli/v1/userguide/cli-usage-filter.html

# JMESPath
# https://jmespath.org/specification.html

echo "Search output at $OUTPUT_DIR/amis.json"
echo ""

AMI_ID=$(aws ec2 describe-images \
	--owners amazon \
	--filters "Name=architecture,Values=x86_64" \
	"Name=is-public,Values=true" \
	"Name=image-type,Values=machine" \
	"Name=name,Values=amzn2-ami-kernel-*-hvm-*" \
	"Name=state,Values=available" \
	"Name=root-device-type,Values=ebs" \
	--query "Images[?CreationDate>'$AMI_CREATED_THIS_MONTH' || CreationDate>'$AMI_CREATED_LAST_MONTH'] | reverse(sort_by(@, &CreationDate)) | [0].ImageId" \
	--output text)

aws ec2 describe-images --image-id $AMI_ID > $OUTPUT_DIR/ami-details.json

echo "Found latest built free-tier linux x86_64 AMI $AMI_ID"
echo ""

aws ssm get-parameters-by-path \
	--path "/aws/service/ami-amazon-linux-latest/" \
	--output json \
	> $OUTPUT_DIR/parameter-image-paths.json 

echo "Search output at $OUTPUT_DIR/parameter-image-paths.json"
echo ""

AMI_ID=$(aws ssm get-parameters \
	--name "/aws/service/ami-amazon-linux-latest/amzn2-ami-kernel-5.10-hvm-x86_64-gp2" \
	--query "Parameters[0].Value" \
	--output text)

echo "Found latest built free-tier linux x86_64 AMI $AMI_ID"
echo ""

aws ec2 describe-images --image-id $AMI_ID > $OUTPUT_DIR/paramter-ami-details.json

unset AWS_DEFAULT_PROFILE

echo ""
echo "Unset default AWS CLI profile ${AWS_DEFAULT_PROFILE}"
