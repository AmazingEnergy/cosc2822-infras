# cosc2822-infras

## How to setup

```bash
chmod 700 ./scripts.sh

./script.sh --action deploy-stack --cfn-stack-name intro-ec2-launch --cfn-template cfn-samples/00-intro/0-ec2-launch-001.yaml

make --action delete-stack --cfn-stack-name intro-ec2-launch

make --action deploy-s3-website-stack --cfn-stack-name s3-static-website --cfn-template cfn-samples/01-s3/0-static-website.yaml --s3-resource-path ./cfn-samples/01-s3/website

make --action delete-s3-website-stack --cfn-stack-name s3-static-website
```
