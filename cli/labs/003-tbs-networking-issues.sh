#!/bin/bash

curl http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | cut -d '"' -f4

aws s3 ls --region us-east-1

aws s3api create-bucket \
  --bucket flowlog1127 \
  --region us-east-1

# /flowlog1127

aws ec2 describe-vpcs \
  --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value,CidrBlock]' \
  --filters "Name=tag:Name,Values='VPC1'"

# vpc-005a4de766530966f
# 10.0.0.0/16

aws ec2 create-flow-logs \
  --resource-type VPC \
  --resource-ids vpc-005a4de766530966f \
  --traffic-type ALL \
  --log-destination-type s3 \
  --log-destination arn:aws:s3:::flowlog1127

# fl-050cff6b692d2361c
# nY+JZ0cn1UOTfIJRQxYjNTzknpb+PdMEvCEnO800GOc=

aws ec2 describe-flow-logs


##########################################################################

aws ec2 describe-instances \
  --filter "Name=ip-address,Values='44.211.161.175'" \
  --query 'Reservations[*].Instances[*].[InstanceId,PublicIpAddress,PrivateIpAddress,SubnetId,Tags[?Key==`Name`].Value,State.Name,NetworkInterfaces[*].[NetworkInterfaceId,VpcId,Groups[*].[GroupId]]]' \
  --output json

# 44.211.161.175
# 10.0.1.185
# eni-07f277b6871f09374
# vpc-005a4de766530966f
# subnet-0e6ca0e77bbfa3ce5
# sg-036509f9b72d5471c

nmap -Pn 44.211.161.175

aws ec2 describe-security-groups \
  --group-ids sg-036509f9b72d5471c \
  --query "SecurityGroups[*].[IpPermissions]"

aws ec2 describe-security-groups \
  --group-ids sg-036509f9b72d5471c \
  --query "SecurityGroups[*].[IpPermissionsEgress]"

aws ec2 describe-route-tables \
  --filter "Name=association.subnet-id,Values='subnet-0e6ca0e77bbfa3ce5'" \
  --query "RouteTables[*].[RouteTableId,Routes]"

# rtb-0b2e2af8ce913bea6

aws ec2 describe-internet-gateways \
  --query "InternetGateways[*].[InternetGatewayId,Attachments[?VpcId=='vpc-005a4de766530966f']]"


# igw-084957d4572377129

aws ec2 create-route \
  --route-table-id rtb-0b2e2af8ce913bea6 \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id igw-084957d4572377129


##########################################################################

mkdir flowlogs

aws s3 cp s3://flowlog1127/ ./flowlogs --recursive

cat 390363829138_vpcflowlogs_us-east-1_fl-050cff6b692d2361c_20241205T0415Z_022cbdb5.log | grep -rn REJECT | grep -rn ' 22 ' . | sort -n -r -k 11

cat 390363829138_vpcflowlogs_us-east-1_fl-050cff6b692d2361c_20241205T0415Z_022cbdb5.log | grep -rn REJECT | grep -rn ' 22 ' . | sort -n -r -k 12

# MomPopCafe EC2 ENI: eni-07f277b6871f09374
# eni-0a143355addcee70b

aws ec2 describe-network-interfaces \
  --query "NetworkInterfaces[?NetworkInterfaceId=='eni-0a143355addcee70b']"


aws ec2 describe-network-acls \
  --filter "Name=association.subnet-id,Values='subnet-0e6ca0e77bbfa3ce5'" \
  --query 'NetworkAcls[*].[NetworkAclId,Entries]'

# acl-001296d40fe13d7b3

aws ec2 delete-network-acl-entry \
  --network-acl-id acl-001296d40fe13d7b3 \
  --ingress \
  --rule-number 40














