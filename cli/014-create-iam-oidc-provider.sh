#!/bin/bash

# remember to change permission
# chmod 700 get-started.sh

# References
# https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services
# https://github.com/aws-actions/configure-aws-credentials?tab=readme-ov-file#oidc
# https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html
#
# ########################################################################################

OIDC_PROVIDER_URL=$1
OIDC_AUDIENCE=$2
OIDC_THUMBPRINT=$3
GITHUB_ORG=$4

OIDC_PROVIDER_ROLE_NAME="github-oidc-provider-role"
OIDC_PROVIDER_BASIC_POLICY_NAME="github-action-basic"

# https://unix.stackexchange.com/a/585027
OIDC_PROVIDER_DOMAIN=$(printf '%s' "$OIDC_PROVIDER_URL" | sed -E 's/^\s*.*:\/\///g')

mkdir ./_output
mkdir ./_output/create-iam-oidc-provider
OUTPUT_DIR="./_output/create-iam-oidc-provider"

# https://docs.aws.amazon.com/cli/latest/reference/iam/list-open-id-connect-providers.html
aws iam list-open-id-connect-providers \
	--output json \
	> $OUTPUT_DIR/existing-oidc-providers.json

echo "Output existing IAM OIDC Providers at $OUTPUT_DIR/existing-oidc-providers.json"
echo ""

# https://jmespath.org/specification.html#contains
EXISTING_OIDC_PROVIDER_ARN=$(aws iam list-open-id-connect-providers \
	--query "OpenIDConnectProviderList[?contains(Arn,'$OIDC_PROVIDER_DOMAIN')] | [0].Arn" \
	--output text)

if [[ ! -z "$EXISTING_OIDC_PROVIDER_ARN" && ! "$EXISTING_OIDC_PROVIDER_ARN" == "None" ]]; then
	echo "Found existing IAM OIDC Provider of Domain: $OIDC_PROVIDER_DOMAIN and ARN: $EXISTING_OIDC_PROVIDER_ARN"
	echo ""
	aws iam delete-open-id-connect-provider --open-id-connect-provider-arn $EXISTING_OIDC_PROVIDER_ARN
fi

EXISTING_OIDC_PROVIDER_BASIC_POLICY_ARN=$(aws iam list-policies \
	--path-prefix "/github/" \
	--query "Policies[?PolicyName=='$OIDC_PROVIDER_BASIC_POLICY_NAME'] | [0].Arn" \
	--output text)

if [[ ! -z "$EXISTING_OIDC_PROVIDER_BASIC_POLICY_ARN" && ! "$EXISTING_OIDC_PROVIDER_BASIC_POLICY_ARN" == "None" ]]; then
	echo "Found existing IAM OIDC Provider Role Policy: $EXISTING_OIDC_PROVIDER_BASIC_POLICY_ARN"
	echo ""

	aws iam detach-role-policy \
		--role-name $OIDC_PROVIDER_ROLE_NAME \
		--policy-arn $EXISTING_OIDC_PROVIDER_BASIC_POLICY_ARN

	aws iam delete-policy --policy-arn $EXISTING_OIDC_PROVIDER_BASIC_POLICY_ARN
fi

EXISTING_OIDC_PROVIDER_ROLE_ARN=$(aws iam list-roles \
	--query "Roles[?RoleName=='$OIDC_PROVIDER_ROLE_NAME'] | [0].RoleName" \
	--output text)

if [[ ! -z "$EXISTING_OIDC_PROVIDER_ROLE_ARN" && ! "$EXISTING_OIDC_PROVIDER_ROLE_ARN" == "None" ]]; then
	echo "Found existing IAM OIDC Provider Role: $EXISTING_OIDC_PROVIDER_ROLE_ARN"
	echo ""

	aws iam delete-role --role-name $OIDC_PROVIDER_ROLE_NAME
fi

echo "Starting to create a new one..."
echo ""

# Make sure the provider's publicly available configuration document and metadata
curl -H "Accept: application/json+v3" "$OIDC_PROVIDER_URL/.well-known/openid-configuration" -o $OUTPUT_DIR/openid-configuration.json

echo "Output well-known OpenID configuration at $OUTPUT_DIR/openid-configuration.json"
echo ""

# https://docs.aws.amazon.com/cli/latest/reference/iam/create-open-id-connect-provider.html
OIDC_PROVIDER_ARN=$(aws iam create-open-id-connect-provider \
	--url $OIDC_PROVIDER_URL \
	--client-id-list $OIDC_AUDIENCE \
	--thumbprint-list $OIDC_THUMBPRINT \
	--tags Key=Purpose,Value=Automation \
	--query "OpenIDConnectProviderArn" \
	--output text)

echo "Created IAM OIDC Provider $OIDC_PROVIDER_ARN"
echo ""

ESCAPED_OIDC_PROVIDER_ARN=$(printf '%s\n' "$OIDC_PROVIDER_ARN" | sed -e 's/[\/&]/\\&/g')

# https://www.cyberciti.biz/faq/how-to-use-sed-to-find-and-replace-text-in-files-in-linux-unix-shell/
sed -i -e "s/<IAM_OIDC_PROVIDER_ARN>/$ESCAPED_OIDC_PROVIDER_ARN/g" ./cli/json/github-oidc-provider-policy-document.json

sed -i -e "s/<GitHubOrg>/$GITHUB_ORG/g" ./cli/json/github-oidc-provider-policy-document.json

aws iam create-role \
	--role-name $OIDC_PROVIDER_ROLE_NAME \
	--assume-role-policy-document file://cli/json/github-oidc-provider-policy-document.json \
	--output json \
	> $OUTPUT_DIR/created-iam-oidc-provider-role.json

aws iam wait role-exists --role-name $OIDC_PROVIDER_ROLE_NAME

OIDC_PROVIDER_BASIC_POLICY_ARN=$(aws iam create-policy \
	--policy-name $OIDC_PROVIDER_BASIC_POLICY_NAME \
	--policy-document file://cli/json/github-action-basic-policy-document.json \
	--path "/github/" \
	--query "Policy.Arn" \
	--output text)

aws iam wait policy-exists --policy-arn $OIDC_PROVIDER_BASIC_POLICY_ARN

aws iam attach-role-policy \
    --policy-arn $OIDC_PROVIDER_BASIC_POLICY_ARN \
    --role-name $OIDC_PROVIDER_ROLE_NAME

aws iam attach-role-policy \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess \
    --role-name $OIDC_PROVIDER_ROLE_NAME

echo "Output newly created IAM OIDC Provider Role at $OUTPUT_DIR/created-iam-oidc-provider-role.json"
echo ""