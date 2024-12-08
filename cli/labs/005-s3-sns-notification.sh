#!/bin/bash

aws s3 mb s3://mompopcafe-luu127 --region us-east-1

aws s3 sync ~/initial-images/ s3://mompopcafe-luu127/images

aws s3 ls s3://mompopcafe-luu127/images/ --human-readable --summarize

# https://docs.aws.amazon.com/cli/latest/reference/sns/create-topic.html
aws sns create-topic \
	--name s3NotificationTopic \
	--attributes DisplayName=s3NotificationTopic

# arn:aws:sns:us-east-1:875675457390:s3NotificationTopic

# https://docs.aws.amazon.com/cli/latest/reference/sns/list-topics.html
aws sns list-topics

# https://docs.aws.amazon.com/cli/latest/reference/sns/get-topic-attributes.html
aws sns get-topic-attributes \
	--topic-arn arn:aws:sns:us-east-1:875675457390:s3NotificationTopic \
	--query "Attributes.Policy"

# https://docs.aws.amazon.com/cli/latest/reference/sns/set-topic-attributes.html
aws sns set-topic-attributes \
	--topic-arn arn:aws:sns:us-east-1:875675457390:s3NotificationTopic \
	--attribute-name Policy \
	--attribute-value file://sns-access-policy.json

# https://docs.aws.amazon.com/cli/latest/reference/sns/subscribe.html
aws sns subscribe \
	--topic-arn arn:aws:sns:us-east-1:875675457390:s3NotificationTopic \
	--protocol email \
	--notification-endpoint s3951127@rmit.edu.vn

# https://docs.aws.amazon.com/cli/latest/reference/sns/list-subscriptions.html
aws sns list-subscriptions

# https://docs.aws.amazon.com/cli/latest/reference/s3api/put-bucket-notification-configuration.html
aws s3api put-bucket-notification-configuration \
	--bucket mompopcafe-luu127 \
	--notification-configuration file://s3-notification-config.json




# mediacouser
###################################################################

# https://docs.aws.amazon.com/cli/latest/reference/s3/ls.html
aws s3 ls --profile mediacouser

aws s3 ls s3://mompopcafe-luu127 \
	--human-readable \
	--summarize \
	--recursive \
	--profile mediacouser

aws s3 cp \
	~/initial-images/Cup-of-Hot-Chocolate.jpg \
	s3://mompopcafe-luu127/images/Cup-of-Hot-Chocolate.jpg

# https://docs.aws.amazon.com/cli/latest/reference/s3/rm.html
aws s3 rm s3://mompopcafe-luu127/images/Cup-of-Hot-Chocolate.jpg

aws s3 sync ~/new-images/ s3://mompopcafe-luu127/images --profile mediacouser

# mompopuser
###################################################################

aws s3 ls --profile mompopuser

aws s3 ls s3://mompopcafe-luu127 \
	--human-readable \
	--summarize \
	--profile mompopuser