#!/bin/bash

# remember to change permission
# chmod 700 get-started.sh

USER_POOL_CLIENT_ID=$1
USER_POOL_CLIENT_SECRET=$2
USER_USERNAME=$3
USER_PASSWORD=$4

mkdir ./_output
mkdir ./_output/get-cognito-access-token
OUTPUT_DIR="./_output/get-cognito-access-token"

# Client-side authentication with Cognito UserPool
# https://docs.aws.amazon.com/cognito/latest/developerguide/authentication-flows-public-server-side.html
#
######################################################

# Function to compute the secret hash
# https://docs.aws.amazon.com/cognito/latest/developerguide/signing-up-users-in-your-app.html#cognito-user-pools-computing-secret-hash
get_secret_hash() {
    local username=$1
    local client_id=$2
    local client_secret=$3
    local data="${username}${client_id}"
    echo -n "$data" | openssl dgst -sha256 -hmac "$client_secret" -binary | openssl enc -base64
}

HASHED_USER_POOL_CLIENT_SECRET=$(get_secret_hash "$USER_USERNAME" "$USER_POOL_CLIENT_ID" "$USER_POOL_CLIENT_SECRET")
echo "Authenticate user with ClientID: $USER_POOL_CLIENT_ID ClientSecret: $HASHED_USER_POOL_CLIENT_SECRET"
echo ""

# https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_InitiateAuth.html
# https://docs.aws.amazon.com/cli/latest/reference/cognito-idp/initiate-auth.html
aws cognito-idp initiate-auth \
	--auth-flow USER_PASSWORD_AUTH \
	--client-id $USER_POOL_CLIENT_ID \
	--auth-parameters USERNAME=$USER_USERNAME,PASSWORD=$USER_PASSWORD,SECRET_HASH=$HASHED_USER_POOL_CLIENT_SECRET \
	--client-metadata aud=test,AUDIENCE=test \
	--output json \
	> $OUTPUT_DIR/initiate-auto-result.json

echo "Output Cognito UserPool USER_PASSWORD_AUTH flow at $OUTPUT_DIR/initiate-auto-result.json"
echo ""

CHALLENGE_NAME=$(jq -r '.ChallengeName' $OUTPUT_DIR/initiate-auto-result.json)
SESSION_TOKEN=$(jq -r '.Session' $OUTPUT_DIR/initiate-auto-result.json)

if [[ "NEW_PASSWORD_REQUIRED" == "$CHALLENGE_NAME" ]]; then
	echo "Response to NEW_PASSWORD_REQUIRED challenge..."
	echo ""

	# https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_RespondToAuthChallenge.html
	# https://docs.aws.amazon.com/cli/latest/reference/cognito-idp/respond-to-auth-challenge.html
	aws cognito-idp respond-to-auth-challenge \
		--client-id $USER_POOL_CLIENT_ID \
		--challenge-name $CHALLENGE_NAME \
		--challenge-responses USERNAME=$USER_USERNAME,NEW_PASSWORD="P@ssword1!",SECRET_HASH=$HASHED_USER_POOL_CLIENT_SECRET \
		--session $SESSION_TOKEN \
		--output json \
		> $OUTPUT_DIR/initiate-auto-result.json
fi


TOKEN_TYPE=$(jq -r '.AuthenticationResult.TokenType' $OUTPUT_DIR/initiate-auto-result.json)
ACCESS_TOKEN=$(jq -r '.AuthenticationResult.AccessToken' $OUTPUT_DIR/initiate-auto-result.json)
EXPIRE_IN=$(jq -r '.AuthenticationResult.ExpiresIn' $OUTPUT_DIR/initiate-auto-result.json)
ID_TOKEN=$(jq -r '.AuthenticationResult.IdToken' $OUTPUT_DIR/initiate-auto-result.json)
REFRESH_TOKEN=$(jq -r '.AuthenticationResult.RefreshToken' $OUTPUT_DIR/initiate-auto-result.json)

echo "Type: $TOKEN_TYPE"
echo ""
echo "Expire in: $EXPIRE_IN"
echo ""
echo "Access token: $ACCESS_TOKEN"
echo ""
echo "ID token: $ID_TOKEN"
echo ""
echo "refresh token: $REFRESH_TOKEN"

# Understanding user pool JSON web tokens (JWTs)
# https://docs.aws.amazon.com/cognito/latest/developerguide/amazon-cognito-user-pools-using-tokens-with-identity-providers.html