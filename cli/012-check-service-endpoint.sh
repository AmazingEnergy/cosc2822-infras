#!/bin/bash

# remember to change permission
# chmod 700 get-started.sh

AWS_PROFILE=$1
CHECK_AWS_SERVICE_NAME=$2
CHECK_AWS_REGION=${AWS_REGION:-"ap-southeast-1"}

if [[ -n "$3" ]]; then
  CHECK_AWS_REGION=$3
fi

mkdir ./_output
mkdir ./_output/check-service-endpoint
OUTPUT_DIR="./_output/check-service-endpoint"

AWS_SERVICE_ENDPOINT=$(aws ssm get-parameter \
  --name /aws/service/global-infrastructure/regions/$CHECK_AWS_REGION/services/$CHECK_AWS_SERVICE_NAME/endpoint \
  --query 'Parameter.Value' \
  --profile $AWS_PROFILE \
  --output text)

if [[ $AWS_SERVICE_ENDPOINT == *"$CHECK_AWS_REGION"* ]]; then
  # the service supports given region
  echo $CHECK_AWS_REGION
else
  # the service doesn't support given region
  echo "us-east-1"
fi

