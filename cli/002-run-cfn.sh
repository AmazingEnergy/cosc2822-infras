#!/bin/bash

# remember to change permission
# chmod 700 get-started.sh

CFN_STACK_NAME=$1
CFN_TEMPLATE_PATH=$2
CFN_STACK_PARAMETERS_PATH=$3
CFN_STACK_REGION=${4:-"ap-southeast-1"}
WAIT=${5:-"true"}

mkdir ./_output
mkdir ./_output/run-cfn
mkdir ./_output/run-cfn/$CFN_STACK_NAME
OUTPUT_DIR="./_output/run-cfn/$CFN_STACK_NAME"


# https://stackoverflow.com/a/69400542
RUN_TIME=$(date +%s)
RUN_DATE=$(date +%F_%T)

chmod 700 ./cli/004-get-public-ipv4.sh
MY_IP=$(./cli/004-get-public-ipv4.sh)

ESCAPED_MY_IP=$(printf '%s\n' "$MY_IP" | sed -e 's/[\/&]/\\&/g')

# https://www.cyberciti.biz/faq/how-to-use-sed-to-find-and-replace-text-in-files-in-linux-unix-shell/
sed -i -e "s/<MY_IP>/$ESCAPED_MY_IP/g" ./$CFN_STACK_PARAMETERS_PATH

# https://docs.aws.amazon.com/cli/latest/reference/cloudformation/validate-template.html#
aws cloudformation validate-template \
	--template-body file://$CFN_TEMPLATE_PATH \
	--region $CFN_STACK_REGION \
	--output json \
	> $OUTPUT_DIR/template-validation-result.json

echo "Output validation result at $OUTPUT_DIR/template-validation-result.json"
echo ""

# https://docs.aws.amazon.com/cli/latest/reference/cloudformation/estimate-template-cost.html
CFN_ESTIMATE_TEMPLATE_COST_URL=$(aws cloudformation estimate-template-cost \
	--template-body file://$CFN_TEMPLATE_PATH \
	--parameters file://$CFN_STACK_PARAMETERS_PATH \
	--query "Url" \
	--region $CFN_STACK_REGION \
	--output text)

if [[ -n "$CFN_ESTIMATE_TEMPLATE_COST_URL" ]]; then
	echo "Generate cost estimation at $CFN_ESTIMATE_TEMPLATE_COST_URL"
	echo ""
else
	echo "Fail to generate cost estimation"
	echo ""
fi

# https://docs.aws.amazon.com/cli/latest/reference/iam/get-role.html
CFN_ROLE_ARN=$(aws iam get-role \
	--role-name CloudFormationRole \
	--query "Role.Arn" \
	--output text)

echo "CloudFormation create Stack under the role: $CFN_ROLE_ARN"
echo ""

CFN_STACK_STATUS=$(aws cloudformation describe-stacks \
	--stack-name $CFN_STACK_NAME \
	--query "Stacks[0].StackStatus" \
	--region $CFN_STACK_REGION \
	--output text)

echo "Found CloudFormation Stack:$CFN_STACK_NAME with Status:$CFN_STACK_STATUS"
echo ""

CFN_CHANGE_SET_TYPE="CREATE"

if [[ "$CFN_STACK_STATUS" == "CREATE_COMPLETE" || "$CFN_STACK_STATUS" == "UPDATE_COMPLETE" || "$CFN_STACK_STATUS" == "UPDATE_ROLLBACK_COMPLETE" || "$CFN_STACK_STATUS" == "UPDATE_FAILED" || "$CFN_STACK_STATUS" == "UPDATE_ROLLBACK_FAILED" ]]; then
	echo "Try to update Stack:$CFN_STACK_NAME"
	CFN_CHANGE_SET_TYPE="UPDATE"

	# https://docs.aws.amazon.com/cli/latest/reference/cloudformation/detect-stack-drift.html
	CFN_STACK_DRIFT_ID=$(aws cloudformation detect-stack-drift \
    --stack-name $CFN_STACK_NAME \
		--query "StackDriftDetectionId" \
		--region $CFN_STACK_REGION \
		--output text)

	if [[ -n "$CFN_STACK_DRIFT_ID" ]]; then
    echo "Stack drift detected $CFN_STACK_DRIFT_ID"
		echo ""
		# https://docs.aws.amazon.com/cli/latest/reference/cloudformation/describe-stack-resource-drifts.html
		aws cloudformation describe-stack-resource-drifts \
			--stack-name $CFN_STACK_NAME \
			--region $CFN_STACK_REGION \
			--output json \
			> $OUTPUT_DIR/stack-resource-drifts.json

		echo "Output Stack resource drifts at $OUTPUT_DIR/stack-resource-drifts.json"
		echo ""
	else
		echo "Not Stack drift detected."
		echo ""
	fi
elif [[ "$CFN_STACK_STATUS" == "CREATE_FAILED" || "$CFN_STACK_STATUS" == "DELETE_FAILED" || "$CFN_STACK_STATUS" == "ROLLBACK_FAILED" || "$CFN_STACK_STATUS" == "ROLLBACK_COMPLETE" ]]; then
  echo "Try to delete Stack:$CFN_STACK_NAME"
	echo ""

	# https://docs.aws.amazon.com/cli/latest/reference/cloudformation/delete-stack.html
	aws cloudformation delete-stack \
    --stack-name $CFN_STACK_NAME \
		--region $CFN_STACK_REGION
	
	echo "Waiting for CloudFormation Stack $CFN_STACK_NAME to be deleted..."
	echo ""
	aws cloudformation wait stack-delete-complete \
		--stack-name $CFN_STACK_NAME \
		--region $CFN_STACK_REGION
fi

# https://docs.aws.amazon.com/cli/latest/reference/cloudformation/create-stack.html
# https://docs.aws.amazon.com/cli/latest/reference/cloudformation/create-change-set.html
aws cloudformation create-change-set \
	--stack-name $CFN_STACK_NAME \
	--change-set-name "$CFN_STACK_NAME-$RUN_TIME" \
	--change-set-type $CFN_CHANGE_SET_TYPE \
	--description "New change set created at $RUN_DATE" \
	--template-body file://$CFN_TEMPLATE_PATH \
	--parameters file://$CFN_STACK_PARAMETERS_PATH \
	--role-arn $CFN_ROLE_ARN \
	--capabilities CAPABILITY_IAM \
	--include-nested-stacks \
	--on-stack-failure ROLLBACK \
	--tags "Key=Purpose,Value=Test" \
	--region $CFN_STACK_REGION \
	--output json \
	> $OUTPUT_DIR/created-change-set.json

echo "Output created ChangeSet at $OUTPUT_DIR/created-change-set.json"
echo ""

CFN_CHANGE_SET_ID=$(jq -r '.Id' $OUTPUT_DIR/created-change-set.json)
CFN_STACK_ID=$(jq -r '.StackId' $OUTPUT_DIR/created-change-set.json)

echo "Waiting for CloudFormation ChangeSet $CFN_CHANGE_SET_ID to be created..."
echo ""

# https://docs.aws.amazon.com/cli/latest/reference/cloudformation/wait/
aws cloudformation wait change-set-create-complete \
	--stack-name $CFN_STACK_ID \
	--change-set-name $CFN_CHANGE_SET_ID \
	--region $CFN_STACK_REGION

CFN_CHANGE_SET_STATUS=$(aws cloudformation describe-change-set \
  --change-set-name $CFN_CHANGE_SET_ID \
	--query "Status" \
	--region $CFN_STACK_REGION \
	--output text)

if [[ "$CFN_CHANGE_SET_STATUS" == "FAILED" ]]; then
	echo "Skip ChangeSet $CFN_CHANGE_SET_ID"
	exit 0
fi

# https://docs.aws.amazon.com/cli/latest/reference/cloudformation/execute-change-set.html
aws cloudformation execute-change-set \
	--stack-name $CFN_STACK_ID \
	--change-set-name $CFN_CHANGE_SET_ID \
	--region $CFN_STACK_REGION

if [[ "$WAIT" == "true"  ]]; then
	if [[ "$CFN_CHANGE_SET_TYPE" == "CREATE" ]]; then
		echo "Waiting for CloudFormation Stack $CFN_STACK_ID to be created..."
		echo ""
		aws cloudformation wait stack-create-complete \
			--stack-name $CFN_STACK_ID \
			--region $CFN_STACK_REGION
	else
		echo "Waiting for CloudFormation Stack $CFN_STACK_ID to be updated..."
		echo ""
		aws cloudformation wait stack-update-complete \
			--stack-name $CFN_STACK_ID \
			--region $CFN_STACK_REGION
	fi
fi

aws cloudformation describe-stacks \
	--stack-name $CFN_STACK_NAME \
	--region $CFN_STACK_REGION \
	--output json \
	> $OUTPUT_DIR/created-stack.json

echo "Output Stack details at $OUTPUT_DIR/$CFN_STACK_NAME.json"
echo ""

# https://docs.aws.amazon.com/cli/latest/reference/cloudformation/list-stacks.html#
aws cloudformation list-stacks \
	--stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE ROLLBACK_COMPLETE IMPORT_COMPLETE \
	--region $CFN_STACK_REGION \
	--output json \
	> $OUTPUT_DIR/active-stacks.json

echo "List all active stacks at $OUTPUT_DIR/active-stacks.json"
echo ""

aws cloudformation list-stacks \
	--stack-status-filter DELETE_COMPLETE \
	--region $CFN_STACK_REGION \
	--output json \
	> $OUTPUT_DIR/archived-stacks.json

echo "List all archived stacks at $OUTPUT_DIR/archived-stacks.json"