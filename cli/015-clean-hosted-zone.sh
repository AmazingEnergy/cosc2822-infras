#!/bin/bash

# remember to change permission
# chmod 700 get-started.sh

HOSTED_ZONE_ID=$1

mkdir ./_output
mkdir ./_output/clean-hosted-zone
OUTPUT_DIR="./_output/clean-hosted-zone"

aws route53 list-resource-record-sets \
	--hosted-zone-id $HOSTED_ZONE_ID \
	--output json \
	> $OUTPUT_DIR/record-sets.json

echo "Output HostedZone record sets at $OUTPUT_DIR/record-sets.json"
echo ""