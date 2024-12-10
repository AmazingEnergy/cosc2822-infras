#!/bin/bash

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
    --cfn-params) CFN_TEMPLATE_PARAMS="$2"; shift ;;
    --cfn-output-key) CFN_OUTPUT_KEY="$2"; shift ;;
    --s3-resource-path) S3_RESOURCE_PATH="$2"; shift ;;
    --route53-domain-name) ROUTE53_DOMAIN_NAME="$2"; shift ;;
    --route53-name-servers) ROUTE53_NAME_SERVERS="$2"; shift ;;
    --route53-hosted-zone) ROUTE53_HOSTED_ZONE="$2"; shift ;;
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
# Deployment
#######################################################

if [[ "$ACTION" == "deploy-before-master" ]]; then
	chmod +x ./cli/002-run-cfn.sh
	./cli/002-run-cfn.sh static-website-stack src/standard/s3-static-website.yaml src/standard/s3-static-website-params.json $REGION
	./cli/002-run-cfn.sh route53-dns-stack src/standard/route53-dns.yaml src/standard/route53-dns-params.json $REGION
	exit 0
fi

if [[ "$ACTION" == "deploy-after-master" ]]; then
	DOMAIN_NAME=$(./cli/008-get-cfn-output.sh route53-dns-stack WildcardDomainName $REGION)
	HOSTED_ZONE_ID=$(./cli/008-get-cfn-output.sh route53-dns-stack HostedZoneId $REGION)
	sed -i -e "s/<DomainName>/$DOMAIN_NAME/g" ./src/standard/acm-certificate-params.json
	sed -i -e "s/<HostedZoneId>/$HOSTED_ZONE_ID/g" ./src/standard/acm-certificate-params.json

	chmod +x ./cli/002-run-cfn.sh
	./cli/002-run-cfn.sh acm-certificate-stack src/standard/acm-certificate.yaml src/standard/acm-certificate-params.json us-east-1

	CERTIFICATE_ARN=$(./cli/008-get-cfn-output.sh acm-certificate-stack CertificateArn us-east-1)
	ESCAPED_CERTIFICATE_ARN=$(printf '%s\n' "$CERTIFICATE_ARN" | sed -e 's/[\/&]/\\&/g')
	sed -i -e "s/<S3StaticWebsiteStack>/static-website-stack/g" ./src/standard/cloud-front-params.json
	sed -i -e "s/<Route53DNSStack>/route53-dns-stack/g" ./src/standard/cloud-front-params.json
	sed -i -e "s/<CertificateArn>/$ESCAPED_CERTIFICATE_ARN/g" ./src/standard/cloud-front-params.json
	sed -i -e "s/<Route53DNSStack>/route53-dns-stack/g" ./src/standard/api-gateway-params.json
	sed -i -e "s/<CognitoStack>/cognito-stack/g" ./src/standard/api-gateway-params.json
	sed -i -e "s/<Route53DNSStack>/route53-dns-stack/g" ./src/standard/apigw-test-endpoint.json
	sed -i -e "s/<ApiGatewayStack>/api-gateway-stack/g" ./src/standard/apigw-test-endpoint.json

	./cli/002-run-cfn.sh cloud-front-stack src/standard/cloud-front.yaml src/standard/cloud-front-params.json $REGION
	./cli/002-run-cfn.sh cognito-stack src/standard/cognito.yaml src/standard/cognito-params.json $REGION
	./cli/002-run-cfn.sh api-gateway-stack src/standard/api-gateway.yaml src/standard/api-gateway-params.json $REGION
	./cli/002-run-cfn.sh apigw-test-api-stack src/standard/apigw-test-endpoint.yaml src/standard/apigw-test-endpoint.json $REGION
	exit 0
fi

if [[ "$ACTION" == "destroy-all-stacks" ]]; then
	chmod +x ./cli/008-get-cfn-output.sh
	chmod +x ./cli/009-clean-s3.sh
	chmod +x ./cli/005-delete-stack.sh

	S3_BUCKET_NAME=$(./cli/008-get-cfn-output.sh static-website-stack S3BucketName $REGION)
	./cli/009-clean-s3.sh $S3_BUCKET_NAME $REGION
	S3_BUCKET_NAME=$(./cli/008-get-cfn-output.sh cloud-front-stack S3BucketName $REGION)
	./cli/009-clean-s3.sh $S3_BUCKET_NAME $REGION

	# delete applications
	./cli/005-delete-stack.sh apigw-test-api-stack $REGION
	# delete advanced stacks
	# TODO: add here
	# delete standard stacks
	./cli/005-delete-stack.sh cloud-front-stack $REGION
	./cli/005-delete-stack.sh static-website-stack $REGION
	./cli/005-delete-stack.sh acm-certificate-stack us-east-1
	./cli/005-delete-stack.sh api-gateway-stack $REGION
	./cli/005-delete-stack.sh route53-dns-stack $REGION
	./cli/005-delete-stack.sh cognito-stack $REGION
	exit 0
fi

if [[ "$ACTION" == "deploy-all-master-stacks" ]]; then
	sed -i -e "s/<NameServers>/$ROUTE53_NAME_SERVERS/g" ./src/master/route53-dns-params.json

	chmod +x ./cli/002-run-cfn.sh
	./cli/002-run-cfn.sh master-route53-dns-stack src/master/route53-dns.yaml src/master/route53-dns-params.json $REGION
	./cli/002-run-cfn.sh master-acm-certificate-stack src/master/acm-certificate.yaml src/master/acm-certificate-params.json $REGION
	exit 0
fi

if [[ "$ACTION" == "destroy-all-master-stacks" ]]; then
	chmod +x ./cli/005-delete-stack.sh
	./cli/005-delete-stack.sh master-route53-dns-stack $REGION
	./cli/005-delete-stack.sh master-acm-certificate-stack $REGION
	exit 0
fi

#######################################################
# Local Test
#######################################################

if [[ "$ACTION" == "deploy-stack" ]]; then
	chmod +x ./cli/002-run-cfn.sh
	./cli/002-run-cfn.sh $CFN_STACK_NAME $CFN_TEMPLATE $CFN_TEMPLATE_PARAMS
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
	shell ./cli/002-run-cfn.sh $CFN_STACK_NAME $CFN_TEMPLATE $CFN_TEMPLATE_PARAMS
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

if [[ "$ACTION" == "clean-hosted-zone" ]]; then
	chmod +x ./cli/015-clean-hosted-zone.sh
	./cli/015-clean-hosted-zone.sh $ROUTE53_HOSTED_ZONE
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