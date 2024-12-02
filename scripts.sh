#!/bin/sh

# remember to change permission
# chmod 700 get-started.sh

POSITIONAL=()

# load args default value
AWS_PROFILE=${COSC2822_INFRAS_AWS_PROFILE:-"cosc2825-devops01"}
CFN_STACK_NAME=${COSC2822_INFRAS_AWS_PROFILE:-"intro-ec2-launch"}
CFN_TEMPLATE=${COSC2822_INFRAS_AWS_PROFILE:-"cfn-samples/00-intro/0-ec2-launch-001.yaml"}
CFN_OUTPUT_KEY_PAIR_ID=${COSC2822_INFRAS_AWS_PROFILE:-"NewKeyPairId"}

# Process named parameters
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --action) ACTION="$2"; shift ;;
    --aws-profile) AWS_PROFILE="$2"; shift ;;
    --cfn-stack-name) CFN_STACK_NAME="$2"; shift ;;
    --cfn-template) CFN_TEMPLATE="$2"; shift ;;
    --cfn-output-key-pair-id) CFN_OUTPUT_KEY_PAIR_ID="$2"; shift ;;
    --cfn-output-key) CFN_OUTPUT_KEY="$2"; shift ;;
    --s3-resource-path) S3_RESOURCE_PATH="$2"; shift ;;
    *) POSITIONAL+=("$1") ;; # Collect positional arguments
  esac
  shift
done

# Restore positional arguments
set -- "${POSITIONAL[@]}"

if [[ -n "$ACTION" ]]; then
	echo "arg --action is required."
	exit 1
fi

if [[ "$ACTION" == "deploy-stack" ]]; then
	chmod 700 ./cli/002-run-cfn.sh
	./cli/002-run-cfn.sh $AWS_PROFILE $CFN_STACK_NAME $CFN_TEMPLATE
	chmod 700 ./cli/003-get-cfn-output-keypair.sh
	./cli/003-get-cfn-output-keypair.sh $AWS_PROFILE $CFN_STACK_NAME $CFN_OUTPUT_KEY_PAIR_ID my-key-pair.pem
	exit 0
fi

if [[ "$ACTION" == "delete-stack" ]]; then
	chmod 700 ./cli/005-delete-stack.sh
	./cli/005-delete-stack.sh $AWS_PROFILE $CFN_STACK_NAME
	exit 0
fi

if [[ "$ACTION" == "deploy-s3-website-stack" ]]; then
	shell chmod 700 ./cli/002-run-cfn.sh
	shell ./cli/002-run-cfn.sh $AWS_PROFILE $CFN_STACK_NAME $CFN_TEMPLATE
	chmod 700 ./cli/008-get-cfn-output.sh
	S3_BUCKET_NAME=$(./cli/008-get-cfn-output.sh $AWS_PROFILE $CFN_STACK_NAME S3BucketName)
	shell chmod 700 ./cli/007-sync-s3.sh
	./cli/007-sync-s3.sh ${aws_profile} $S3_BUCKET_NAME $S3_RESOURCE_PATH
	exit 0
fi

if [[ "$ACTION" == "delete-s3-website-stack" ]]; then
	chmod 700 ./cli/008-get-cfn-output.sh
	S3_BUCKET_NAME=$(./cli/008-get-cfn-output.sh $AWS_PROFILE $CFN_STACK_NAME S3BucketName)
	chmod 700 ./cli/009-clean-s3.sh
	./cli/009-clean-s3.sh $AWS_PROFILE $S3_BUCKET_NAME
	chmod 700 ./cli/005-delete-stack.sh
	./cli/005-delete-stack.sh $AWS_PROFILE $CFN_STACK_NAME
	exit 0
fi

if [[ "$ACTION" == "search-ami" ]]; then
	chmod 700 ./cli/001-search-ami.sh
	./cli/001-search-ami.sh ${aws_profile}
	exit 0
fi

if [[ "$ACTION" == "my-ip" ]]; then
	chmod 700 ./cli/004-get-public-ipv4.sh
	./cli/004-get-public-ipv4.sh
	exit 0
fi
