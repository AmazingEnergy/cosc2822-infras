# cosc2822-infras

## Management

The following commands/actions is manually used by **AWS administrators**.

```bash
chmod +x ./scripts.sh

./scripts.sh \
  --action create-iam-oidc-provider \
  --oidc-provider-url https://token.actions.githubusercontent.com \
  --oidc-audience sts.amazonaws.com \
  --oidc-thumbprint ffffffffffffffffffffffffffffffffffffffff \
  --github-org AmazingEnergy

./scripts.sh \
  --action create-iam-oidc-provider \
  --aws-profile cosc2825-devops01 \
  --oidc-provider-url https://token.actions.githubusercontent.com \
  --oidc-audience sts.amazonaws.com \
  --oidc-thumbprint ffffffffffffffffffffffffffffffffffffffff \
  --github-org AmazingEnergy

```

## Deployment

The following commands/actions would be run by GitHub Actions.

```bash
chmod +x ./scripts.sh

# deploy all stacks to working account and master account

./scripts.sh --action deploy-before-master
./scripts.sh --action deploy-all-master-stacks
./scripts.sh --action deploy-after-master

# destroy all stacks from working account and master account

./scripts.sh --action destroy-all-stacks
./scripts.sh --action destroy-all-master-stacks
```

## Local Test

The following commands/actions is only used for **local testing**.

```bash
chmod +x ./scripts.sh

# ec2 instances

./scripts.sh \
  --action deploy-stack \
  --cfn-stack-name intro-ec2-launch \
  --cfn-template cfn-samples/00-intro/0-ec2-launch-001.yaml

./scripts.sh \
  --action delete-stack \
  --cfn-stack-name intro-ec2-launch

# s3 website

./scripts.sh \
  --action deploy-s3-website-stack \
  --cfn-stack-name s3-static-website \
  --cfn-template cfn-samples/01-s3/0-static-website.yaml \
  --s3-resource-path ./cfn-samples/01-s3/website

./scripts.sh \
  --action delete-s3-website-stack \
  --cfn-stack-name s3-static-website

# route53 domain

./scripts.sh \
  --action deploy-domain-stack \
  --cfn-stack-name route53-domain \
  --cfn-template cfn-samples/02-route53/0-domain.yaml \
  --route53-domain-name grp6asm3.com

./scripts.sh \
  --action delete-domain-stack \
  --cfn-stack-name route53-domain \
  --route53-domain-name grp6asm3.com

```

## Utils

Some useful commands/actions

```bash
chmod +x ./scripts.sh

./scripts.sh \
  --action check-service-endpoint \
  --aws-service-name route53 \
  --region ap-southeast-1

./scripts.sh \
  --action check-service-endpoint \
  --aws-service-name s3 \
  --region ap-southeast-1

./scripts.sh --action search-ami

./scripts.sh \
  --action get-access-token \
  --username <username> \
  --password <password> \
  --aws-profile cosc2825-devops01 \
  --region ap-southeast-1

```
