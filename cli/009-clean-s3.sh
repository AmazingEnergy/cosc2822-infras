#!/bin/bash

# remember to change permission
# chmod 700 get-started.sh

S3_BUCKET_NAME=$1

mkdir ./_output
mkdir ./_output/clean-s3
OUTPUT_DIR="./_output/clean-s3"

FULL_S3_BUCKET_NAME=$(aws s3 ls | grep $S3_BUCKET_NAME | cut -d' ' -f3)

if [[ -n "$FULL_S3_BUCKET_NAME" ]]; then
	echo "Found S3 bucket with name $FULL_S3_BUCKET_NAME"
	echo ""

	aws s3 ls s3://$FULL_S3_BUCKET_NAME \
		--recursive \
		--output text \
		> $OUTPUT_DIR/all-s3-items.txt

	echo "List all S3 items at $OUTPUT_DIR/all-s3-items.txt"
	echo ""

	aws s3 rm s3://$FULL_S3_BUCKET_NAME --recursive

	echo "Done clean resources to S3."
	echo ""
else
	echo "Not found S3 bucket $S3_BUCKET_NAME"
	echo ""
fi