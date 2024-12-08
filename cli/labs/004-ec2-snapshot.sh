#!/bin/bash

VOLUME_ID=$(aws ec2 describe-instances \
  --filter 'Name=tag:Name,Values=Processor' \
  --query 'Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.{VolumeId:VolumeId}' \
  --output text)

echo "Found EC2 volume $VOLUME_ID"

INSTANCE_ID=$(aws ec2 describe-instances \
  --filters 'Name=tag:Name,Values=Processor' \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text)

echo "Found EC2 instance $INSTANCE_ID"

aws ec2 stop-instances --instance-ids $INSTANCE_ID

aws ec2 wait instance-stopped --instance-id $INSTANCE_ID

echo "EC2 instance $INSTANCE_ID was shuted down"

SNAPSHOT_ID=$(aws ec2 create-snapshot --volume-id $VOLUME_ID \
  --query "SnapshotId" \
  --output text)

aws ec2 wait snapshot-completed --snapshot-id $SNAPSHOT_ID

echo "Created a new snapshot $SNAPSHOT_ID"

aws ec2 start-instances --instance-ids $INSTANCE_ID

aws ec2 wait instance-running --instance-id $INSTANCE_ID

echo "EC2 instance $INSTANCE_ID restarted"



######################################################################

echo "* * * * *  backupjob.sh >> /tmp/cronlog 2>&1" > cronjob

echo "* * * * *  /home/ec2-user/backupjob.sh >> /tmp/cronlog 2>&1" > cronjob

aws ec2 describe-snapshots --filters "Name=volume-id,Values=vol-0666604eae41ad900"

sudo ln -s /home/ec2-user/backupjob.sh /usr/local/bin


######################################################################

aws s3api put-bucket-versioning \
  --bucket module8-lab5-bucket \
  --versioning-configuration Status=Enabled

aws s3api list-object-versions \
  --bucket module8-lab5-bucket \
  --prefix file2.txt

# wRKv587xAdrpUe_FKY32Wl38tjtL7g20
# ClNVPIBmNtwVIoQqG.3Pfh2Bu31frepw

aws s3api get-object \
  --bucket module8-lab5-bucket \
  --key file2.txt \
  --version-id "ClNVPIBmNtwVIoQqG.3Pfh2Bu31frepw" files/file2.txt