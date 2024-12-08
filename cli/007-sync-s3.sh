#!/bin/bash

# remember to change permission
# chmod 700 get-started.sh

S3_BUCKET_NAME=$1
RESOURCE_PATH=$2

mkdir ./_output
mkdir ./_output/sync-s3
OUTPUT_DIR="./_output/sync-s3"

FULL_S3_BUCKET_NAME=$(aws s3 ls | grep $S3_BUCKET_NAME | cut -d' ' -f3)

if [[ -n "$FULL_S3_BUCKET_NAME" ]]; then
	echo "Found S3 bucket with name $FULL_S3_BUCKET_NAME"
	echo ""

	aws s3 sync $RESOURCE_PATH s3://$FULL_S3_BUCKET_NAME

	echo "Done sync resources to S3."
	echo ""
else
	echo "Not found S3 bucket $S3_BUCKET_NAME"
	echo ""
fi