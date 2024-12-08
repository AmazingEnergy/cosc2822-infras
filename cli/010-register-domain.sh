#!/bin/bash

# remember to change permission
# chmod 700 get-started.sh

DOMAIN_NAME=$1

mkdir ./_output
mkdir ./_output/register-domain
OUTPUT_DIR="./_output/register-domain"

DOMAIN_NAME_AVAILABILITY=$(aws route53domains check-domain-availability \
  --domain-name $DOMAIN_NAME \
  --query "Availability" \
  --region us-east-1 \
  --output text)

if [[ -z "$DOMAIN_NAME_AVAILABILITY" || "$DOMAIN_NAME_AVAILABILITY" == "UNAVAILABLE" ]]; then
  echo "Domain name '$DOMAIN_NAME' is not available"
  exit 1
else
  echo "Domain name '$DOMAIN_NAME' is available"
fi

OPERATION_ID=$(aws route53domains register-domain \
  --domain-name $DOMAIN_NAME \
  --duration-in-years 1 \
  --no-auto-renew \
  --admin-contact file://cli/json/route53-domain-contact.json \
  --registrant-contact file://cli/json/route53-domain-contact.json \
  --tech-contact file://cli/json/route53-domain-contact.json \
  --billing-contact file://cli/json/route53-domain-contact.json \
  --privacy-protect-admin-contact \
  --privacy-protect-registrant-contact \
  --privacy-protect-tech-contact \
  --privacy-protect-billing-contact \
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

  echo "Domain registration is $OPERATION_STATUS"
  echo ""

  if [[ $OPERATION_STATUS == "SUCCESSFUL" || $OPERATION_STATUS == "FAILED" ]]; then 
    break
  else
    sleep 10
  fi
done