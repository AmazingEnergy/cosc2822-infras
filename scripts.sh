#!/bin/sh

# remember to change permission
# chmod +x scripts.sh

POSITIONAL=()

# load args default value
AWS_PROFILE=${COSC2822_INFRAS_AWS_PROFILE:-""}
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
    --oidc-provider-url) IAM_OIDC_PROVIDER_URL="$2"; shift ;;
    --oidc-audience) IAM_OIDC_AUDIENCE="$2"; shift ;;
    --oidc-thumbprint) IAM_OIDC_THUMBPRINT="$2"; shift ;;
    --github-org) GITHUB_ORG="$2"; shift ;;
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

if [ -n "$AWS_PROFILE" ]; then
	unset AWS_ACCESS_KEY_ID
	unset AWS_SECRET_ACCESS_KEY
	unset AWS_DEFAULT_PROFILE
	export AWS_DEFAULT_PROFILE=$AWS_PROFILE
	echo "Set default AWS CLI profile ${AWS_DEFAULT_PROFILE}"
	echo ""
fi

chmod +x ./cli/013-check-iam-caller.sh
./cli/013-check-iam-caller.sh


#######################################################
# CloudFormation Stacks
#######################################################

if [[ "$ACTION" == "deploy-stack" ]]; then
	chmod +x ./cli/002-run-cfn.sh
	./cli/002-run-cfn.sh $CFN_STACK_NAME $CFN_TEMPLATE
	chmod +x ./cli/003-get-cfn-output-keypair.sh
	./cli/003-get-cfn-output-keypair.sh $CFN_STACK_NAME NewKeyPairId my-key-pair.pem
	exit 0
fi

if [[ "$ACTION" == "delete-stack" ]]; then
	chmod +x ./cli/005-delete-stack.sh
	./cli/005-delete-stack.sh $CFN_STACK_NAME
	exit 0
fi

if [[ "$ACTION" == "deploy-s3-website-stack" ]]; then
	shell chmod +x ./cli/002-run-cfn.sh
	shell ./cli/002-run-cfn.sh $CFN_STACK_NAME $CFN_TEMPLATE
	chmod +x ./cli/008-get-cfn-output.sh
	S3_BUCKET_NAME=$(./cli/008-get-cfn-output.sh $CFN_STACK_NAME S3BucketName)
	shell chmod +x ./cli/007-sync-s3.sh
	./cli/007-sync-s3.sh ${aws_profile} $S3_BUCKET_NAME $S3_RESOURCE_PATH
	exit 0
fi

if [[ "$ACTION" == "delete-s3-website-stack" ]]; then
	chmod +x ./cli/008-get-cfn-output.sh
	S3_BUCKET_NAME=$(./cli/008-get-cfn-output.sh $CFN_STACK_NAME S3BucketName)
	chmod +x ./cli/009-clean-s3.sh
	./cli/009-clean-s3.sh $S3_BUCKET_NAME
	chmod +x ./cli/005-delete-stack.sh
	./cli/005-delete-stack.sh $CFN_STACK_NAME
	exit 0
fi

if [[ "$ACTION" == "deploy-domain-stack" ]]; then
	chmod +x ./cli/010-register-domain.sh
	./cli/010-register-domain.sh $ROUTE53_DOMAIN_NAME
	exit 0
fi

if [[ "$ACTION" == "delete-domain-stack" ]]; then
	chmod +x ./cli/011-delete-domain.sh
	./cli/011-delete-domain.sh $ROUTE53_DOMAIN_NAME
	exit 0
fi


#######################################################
# Utils
#######################################################

if [[ "$ACTION" == "search-ami" ]]; then
	chmod +x ./cli/001-search-ami.sh
	./cli/001-search-ami.sh
	exit 0
fi

if [[ "$ACTION" == "my-ip" ]]; then
	chmod +x ./cli/004-get-public-ipv4.sh
	./cli/004-get-public-ipv4.sh
	exit 0
fi

if [[ "$ACTION" == "check-service-endpoint" ]]; then
	chmod +x ./cli/012-check-service-endpoint.sh
	./cli/012-check-service-endpoint.sh $AWS_PROFILE $AWS_SERVICE_NAME $REGION
	exit 0
fi


###########################################################################
# Management
# the following actions only manually made by administrator, no automation
###########################################################################

if [[ "$ACTION" == "create-iam-oidc-provider" ]]; then
	chmod +x ./cli/014-create-iam-oidc-provider.sh
	./cli/014-create-iam-oidc-provider.sh $IAM_OIDC_PROVIDER_URL $IAM_OIDC_AUDIENCE $IAM_OIDC_THUMBPRINT $GITHUB_ORG
	exit 0
fi