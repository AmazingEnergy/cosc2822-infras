#!/bin/bash

# remember to change permission
# chmod 700 get-started.sh

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY

export AWS_DEFAULT_PROFILE=$1

echo "Set default AWS CLI profile ${AWS_DEFAULT_PROFILE}"
echo ""

DOMAIN_NAME=$2

mkdir ./_output
mkdir ./_output/register-domain
OUTPUT_DIR="./_output/register-domain"

OPERATION_ID=$(aws route53domains delete-domain \
  --domain-name $DOMAIN_NAME \
  --query "OperationId" \
  --region us-east-1 \
  --output text)


max=30
for i in `seq 2 $max`
do
  OPERATION_STATUS=$(aws route53domains get-operation-detail \
    --operation-id $OPERATION_ID \
    --query "Status" \
  	--region us-east-1 \
    --output text)

  echo "Domain deletion is $OPERATION_STATUS"
  echo ""

  if [["$OPERATION_STATUS" == "SUCCESSFUL" ]]; then 
    break
  else
    sleep 10
  fi
done

unset AWS_DEFAULT_PROFILE

echo ""
echo "Unset default AWS CLI profile ${AWS_DEFAULT_PROFILE}"