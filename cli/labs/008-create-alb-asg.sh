
18.215.118.25

ec2-3-234-182-4.compute-1.amazonaws.com

ami-042fa689d6222ab99

vpc-02eb735dde430f002

sg-03bb38cb1400c00fc

subnet-0685d057f78562893
subnet-0d08637f5ebe93a87

subnet-0393253fd910d7c85
subnet-0f36021002bd47379

__________________________________________________________________________________


aws elbv2 create-load-balancer \
  --name webserverloadbalancer \
  --subnets subnet-0393253fd910d7c85 subnet-0f36021002bd47379 \
  --security-groups sg-03bb38cb1400c00fc

# arn:aws:elasticloadbalancing:us-east-1:992382767347:loadbalancer/app/webserverloadbalancer/3594739dcb9b7d3d

aws elbv2 create-target-group \
  --name webserver-app \
  --target-type instance \
  --health-check-path /index.html \
  --healthy-threshold-count 2 \
  --health-check-interval-seconds 10  \
  --protocol HTTP \
  --port 80 \
  --vpc-id vpc-02eb735dde430f002

# arn:aws:elasticloadbalancing:us-east-1:992382767347:targetgroup/webserver-app/5b59b8a19b0d4e45

aws elbv2 create-listener \
  --load-balancer-arn arn:aws:elasticloadbalancing:us-east-1:992382767347:loadbalancer/app/webserverloadbalancer/3594739dcb9b7d3d \
  --protocol HTTP \
  --port 80 \
  --default-action "Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:us-east-1:992382767347:targetgroup/webserver-app/5b59b8a19b0d4e45"

# arn:aws:elasticloadbalancing:us-east-1:992382767347:listener/app/webserverloadbalancer/3594739dcb9b7d3d/82977fcbfb0770a5

# https://docs.aws.amazon.com/cli/latest/reference/ec2/create-launch-template.html
aws ec2 create-launch-template \
    --launch-template-name WebServerLaunchTemplate \
    --version-description AutoScalingVersion1 \
    --launch-template-data '{ "NetworkInterfaces": [ { "DeviceIndex": 0, "AssociatePublicIpAddress": false, "Groups": [ "sg-03bb38cb1400c00fc" ], "DeleteOnTermination": true } ], "ImageId": "ami-042fa689d6222ab99", "InstanceType": "t2.micro", "TagSpecifications": [ { "ResourceType": "instance", "Tags": [ { "Key": "Name", "Value": "Auto-Scaled-Instance" } ] } ] }'

# lt-07055ba2925ce5001

aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name WebServersASGroup \
  --launch-template LaunchTemplateId=lt-07055ba2925ce5001 \
  --desired-capacity 2 \
  --min-size 2 \
  --max-size 4 \
  --vpc-zone-identifier "subnet-0393253fd910d7c85, subnet-0f36021002bd47379" \
  --target-group-arns arn:aws:elasticloadbalancing:us-east-1:992382767347:targetgroup/webserver-app/5b59b8a19b0d4e45 \
  --health-check-type ELB \
  --health-check-grace-period 60

# arn:aws:autoscaling:us-east-1:992382767347:autoScalingGroup:33fcb3f8-8563-42e8-a6a8-8876cf1e4ba4:autoScalingGroupName/WebServersASGroup

aws autoscaling put-scaling-policy \
  --auto-scaling-group-name WebServersASGroup \
  --policy-name MyScalingPolicy \
  --policy-type TargetTrackingScaling \
  --target-tracking-configuration '{ "TargetValue": 45.0, "PredefinedMetricSpecification": { "PredefinedMetricType": "ASGAverageCPUUtilization" } }'

#

aws autoscaling create-launch-configuration \
  --launch-configuration-name WebServerLaunchTemplate \
  --image-id ami-042fa689d6222ab99 \
  --instance-type t2.micro \
  --security-groups sg-03bb38cb1400c00fc \
  --instance-monitoring Enabled=true

#


__________________________________________________________________________________

# https://docs.aws.amazon.com/cli/latest/reference/autoscaling/update-auto-scaling-group.html
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name WebServersASGroup \
  --health-check-grace-period 300

# https://docs.aws.amazon.com/cli/latest/reference/elbv2/modify-target-group.html
aws elbv2 modify-target-group \
    --target-group-arn arn:aws:elasticloadbalancing:us-east-1:992382767347:targetgroup/webserver-app/5b59b8a19b0d4e45 \
    --health-check-protocol HTTP \
    --health-check-port 80 \
    --health-check-path /index.php \
    --health-check-timeout-seconds 10 \
    --health-check-interval-seconds 15 \
    --healthy-threshold-count 2 \
    --unhealthy-threshold-count 2 \
    --matcher HttpCode='200'

# https://docs.aws.amazon.com/cli/latest/reference/elbv2/set-subnets.html
aws elbv2 set-subnets \
  --load-balancer-arn arn:aws:elasticloadbalancing:us-east-1:992382767347:loadbalancer/app/webserverloadbalancer/3594739dcb9b7d3d \
  --subnets subnet-0685d057f78562893 subnet-0d08637f5ebe93a87