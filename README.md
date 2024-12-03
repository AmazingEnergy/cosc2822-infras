# cosc2822-infras

## Deployment

```bash
chmod 700 ./scripts.sh

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

```bash
./scripts.sh \
  --action check-service-endpoint \
  --aws-service-name route53 \
  --region ap-southeast-1

./scripts.sh \
  --action check-service-endpoint \
  --aws-service-name s3 \
  --region ap-southeast-1
```
