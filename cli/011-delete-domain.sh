#!/bin/bash

# remember to change permission
# chmod 700 get-started.sh

DOMAIN_NAME=$1

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