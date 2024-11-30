#!/bin/sh

# remember to change permission
# chmod 700 get-started.sh

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY

export AWS_DEFAULT_PROFILE="cosc2825-devops01"

echo "Set default AWS CLI profile ${AWS_DEFAULT_PROFILE}"
echo ""

# TODO: code here
aws s3 ls

unset AWS_DEFAULT_PROFILE

echo ""
echo "Unset default AWS CLI profile ${AWS_DEFAULT_PROFILE}"