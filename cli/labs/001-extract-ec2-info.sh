#!/bin/bash

aws ec2 describe-instances \
  --filters "Name=tag:Name,Values= MomPopCafeInstance" \
  --query "Reservations[*].Instances[*].[InstanceId,InstanceType,PublicDnsName,PublicIpAddress,Placement.AvailabilityZone,VpcId,SecurityGroups[*].GroupId]"

INSTANCE_ID="i-09e7fa36e0895f405",
INSTANCE_TYPE="t2.small",
INSTANCE_PUBLIC_DNS="ec2-44-203-122-176.compute-1.amazonaws.com",
INSTANCE_IPV4="44.203.122.176",
INSTANCE_AZ="us-east-1a",
INSTANCE_VPC_ID="vpc-039ba9bad7fee786c",
INSTANCE_SG="sg-0d5c5569f61530d6e"


aws ec2 describe-vpcs --vpc-ids vpc-039ba9bad7fee786c \
  --filters "Name=tag:Name,Values= MomPopCafe VPC" \
  --query "Vpcs[*].CidrBlock"

# 10.200.0.0/20

aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=vpc-039ba9bad7fee786c" \
  --query "Subnets[*].[SubnetId,CidrBlock]"

# subnet-0603d568626fe4596
# 10.200.0.0/24

aws ec2 describe-availability-zones \
  --filters "Name=region-name,Values=us-east-1" \
  --query "AvailabilityZones[*].ZoneName"

# us-east-1a
# us-east-1b
# us-east-1c
# us-east-1d
# us-east-1e
# us-east-1f

# Number of orders: 3

echo "MomPopCafeInstance Instance ID: $INSTANCE_ID"
echo "MomPopCafeInstance Instance Type: $INSTANCE_TYPE"
echo "MomPopCafeInstance Public DNS Name: $INSTANCE_PUBLIC_DNS"
echo "MomPopCafeInstance Public IP Address: $INSTANCE_IPV4"
echo "MomPopCafeInstance Availability Zone: $INSTANCE_AZ"
echo "MomPopCafeInstance VPC ID: $INSTANCE_VPC_ID"
echo "MomPopCafeSecurityGroup Group ID: $INSTANCE_SG"


####################################################################


aws ec2 create-security-group \
  --group-name MomPopCafeDatabaseSG \
  --description "Security group for Mom Pop Cafe database" \
  --vpc-id vpc-039ba9bad7fee786c

# sg-024500bd12ceadda2

aws ec2 authorize-security-group-ingress \
  --group-id sg-024500bd12ceadda2 \
  --protocol tcp --port 3306 \
  --source-group sg-0d5c5569f61530d6e

# 

aws ec2 describe-security-groups \
  --query "SecurityGroups[*].[GroupName,GroupId,IpPermissions]" \
  --filters "Name=group-name,Values='MomPopCafeDatabaseSG'"

# 

aws ec2 create-subnet \
  --vpc-id vpc-039ba9bad7fee786c \
  --cidr-block 10.200.2.0/23 \
  --availability-zone us-east-1a

# subnet-06394c0b77f9e5a72

aws ec2 create-subnet \
  --vpc-id vpc-039ba9bad7fee786c \
  --cidr-block 10.200.4.0/23 \
  --availability-zone us-east-1b

# subnet-0fd6beb7fe78ac4cb

aws rds create-db-subnet-group \
  --db-subnet-group-name "MomPopCafeDB Subnet Group" \
  --db-subnet-group-description "DB subnet group for Mom & Pop Cafe" \
  --subnet-ids subnet-06394c0b77f9e5a72 subnet-0fd6beb7fe78ac4cb \
  --tags "Key=Name,Value= MomPopCafeDatabaseSubnetGroup"

# arn:aws:rds:us-east-1:992382697296:subgrp:mompopcafedb subnet group

aws rds create-db-instance \
  --db-instance-identifier MomPopCafeDBInstance \
  --engine mariadb \
  --engine-version 10.6.14 \
  --db-instance-class db.t3.micro \
  --allocated-storage 20 \
  --availability-zone us-east-1a  \
  --db-subnet-group-name "MomPopCafeDB Subnet Group" \
  --vpc-security-group-ids sg-024500bd12ceadda2 \
  --no-publicly-accessible \
  --master-username root --master-user-password 'Re:Start!9'

# arn:aws:rds:us-east-1:992382697296:db:mompopcafedbinstance

aws rds describe-db-instances \
  --db-instance-identifier MomPopCafeDBInstance \
  --query "DBInstances[*].[Endpoint.Address,AvailabilityZone,PreferredBackupWindow,BackupRetentionPeriod,DBInstanceStatus]"

# mompopcafedbinstance.clk2i6iusv6i.us-east-1.rds.amazonaws.com

aws rds modify-db-instance \
    --db-instance-identifier MomPopCafeDBInstance \
    --vpc-security-group-ids sg-024500bd12ceadda2

####################################################################

mysqldump --user=root --password='Re:Start!9' \
  --databases mom_pop_db \
  --add-drop-database \
  > mompopdb-backup.sql

mysql --user=root --password='Re:Start!9' \
  --host='mompopcafedbinstance.clk2i6iusv6i.us-east-1.rds.amazonaws.com' \
  < mompopdb-backup.sql
