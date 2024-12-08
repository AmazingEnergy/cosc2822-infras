#!/bin/sh

# remember to change permission
# chmod 700 get-started.sh

POSITIONAL=()

# load args default value
AWS_PROFILE=${COSC2822_INFRAS_AWS_PROFILE:-"default"}
CFN_STACK_NAME=${COSC2822_INFRAS_AWS_PROFILE:-"intro-ec2-launch"}
CFN_TEMPLATE=${COSC2822_INFRAS_AWS_PROFILE:-"cfn-samples/00-intro/0-ec2-launch-001.yaml"}

# Process named parameters
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --action) ACTION="$2"; shift ;;
    --region) REGION="$2"; shift ;;
    --aws-profile) AWS_PROFILE="$2"; shift ;;
    --cfn-stack-name) CFN_STACK_NAME="$2"; shift ;;
    --cfn-template) CFN_TEMPLATE="$2"; shift ;;
    --cfn-output-key) CFN_OUTPUT_KEY="$2"; shift ;;
    --s3-resource-path) S3_RESOURCE_PATH="$2"; shift ;;
    --route53-domain-name) ROUTE53_DOMAIN_NAME="$2"; shift ;;
    --aws-service-name) AWS_SERVICE_NAME="$2"; shift ;;
    *) POSITIONAL+=("$1") ;; # Collect positional arguments
  esac
  shift
done

# Restore positional arguments
set -- "${POSITIONAL[@]}"

if [[ -z "$ACTION" ]]; then
	echo "arg --action is required."
	exit 1
fi

if [[ -n "$AWS_PROFILE" ]]; then
	unset AWS_ACCESS_KEY_ID
	unset AWS_SECRET_ACCESS_KEY
	unset AWS_DEFAULT_PROFILE
	export AWS_DEFAULT_PROFILE=$1
	echo "Set default AWS CLI profile ${AWS_DEFAULT_PROFILE}"
	echo ""
fi

if [[ "$ACTION" == "deploy-stack" ]]; then
	chmod 700 ./cli/002-run-cfn.sh
	./cli/002-run-cfn.sh $CFN_STACK_NAME $CFN_TEMPLATE
	chmod 700 ./cli/003-get-cfn-output-keypair.sh
	./cli/003-get-cfn-output-keypair.sh $CFN_STACK_NAME NewKeyPairId my-key-pair.pem
	exit 0
fi

if [[ "$ACTION" == "delete-stack" ]]; then
	chmod 700 ./cli/005-delete-stack.sh
	./cli/005-delete-stack.sh $CFN_STACK_NAME
	exit 0
fi

if [[ "$ACTION" == "deploy-s3-website-stack" ]]; then
	shell chmod 700 ./cli/002-run-cfn.sh
	shell ./cli/002-run-cfn.sh $CFN_STACK_NAME $CFN_TEMPLATE
	chmod 700 ./cli/008-get-cfn-output.sh
	S3_BUCKET_NAME=$(./cli/008-get-cfn-output.sh $CFN_STACK_NAME S3BucketName)
	shell chmod 700 ./cli/007-sync-s3.sh
	./cli/007-sync-s3.sh ${aws_profile} $S3_BUCKET_NAME $S3_RESOURCE_PATH
	exit 0
fi

if [[ "$ACTION" == "delete-s3-website-stack" ]]; then
	chmod 700 ./cli/008-get-cfn-output.sh
	S3_BUCKET_NAME=$(./cli/008-get-cfn-output.sh $CFN_STACK_NAME S3BucketName)
	chmod 700 ./cli/009-clean-s3.sh
	./cli/009-clean-s3.sh $S3_BUCKET_NAME
	chmod 700 ./cli/005-delete-stack.sh
	./cli/005-delete-stack.sh $CFN_STACK_NAME
	exit 0
fi

if [[ "$ACTION" == "deploy-domain-stack" ]]; then
	chmod 700 ./cli/010-register-domain.sh
	./cli/010-register-domain.sh $ROUTE53_DOMAIN_NAME
	exit 0
fi

if [[ "$ACTION" == "delete-domain-stack" ]]; then
	chmod 700 ./cli/011-delete-domain.sh
	./cli/011-delete-domain.sh $ROUTE53_DOMAIN_NAME
	exit 0
fi


#######################################################
# Utils
#######################################################

if [[ "$ACTION" == "search-ami" ]]; then
	chmod 700 ./cli/001-search-ami.sh
	./cli/001-search-ami.sh
	exit 0
fi

if [[ "$ACTION" == "my-ip" ]]; then
	chmod 700 ./cli/004-get-public-ipv4.sh
	./cli/004-get-public-ipv4.sh
	exit 0
fi

if [[ "$ACTION" == "check-service-endpoint" ]]; then
	chmod 700 ./cli/012-check-service-endpoint.sh
	./cli/012-check-service-endpoint.sh $AWS_PROFILE $AWS_SERVICE_NAME $REGION
	exit 0
fi
