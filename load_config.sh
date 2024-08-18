#!/bin/bash

# Must modify below.
# Replace YOUR_KEY_PAIR_PATH with the path to your ssh public key.
export TF_VAR_key_path=YOUR_KEY_PAIR_PATH

# Replace YOUR_PKG_BUCKET_NAME with the name of the bucket to which the downloaded packages are uploaded.
export TF_VAR_pkg_bucket=YOUR_PKG_BUCKET_NAME

# Replace YOUR_IAM_ROLE with the name of the role with the `AmazonS3FullAccess` policy attached.
export TF_VAR_iam_role=YOUR_IAM_ROLE

# Replace YOUR_REGION with the region in which you want to deploy Spark (i.e. us-east-1).
export TF_VAR_region=YOUR_REGION

# Replace YOUR_SUBNET_CIDR with the CIDR block of the subnet in which you want to deploy Spark. (i.e. 172.41.41.0/20).
export TF_VAR_subnet_cidr=YOUR_SUBNET_CIDR

# Modify if you are willing to pay more for more powerful ec2 instances.
export TF_VAR_spark_driver_memory="480m" # Minimum
export TF_VAR_spark_driver_core="1"
# export TF_VAR_spark_executor_memory="1g"
export TF_VAR_spark_executor_memory="480m"
export TF_VAR_spark_executor_core="1"
export TF_VAR_spark_executor_num="1"

# Modify if you understand what you are doing it for.
export TF_VAR_ec2_ami="ami-0ae8f15ae66fe8cda"
export TF_VAR_ec2_master="t2.micro"
export TF_VAR_ec2_slave="t2.micro"
# export TF_VAR_ec2_slave="t2.small"
export TF_VAR_jdk_name="openlogic-openjdk-11.0.24+8-linux-x64"
export TF_VAR_spark_name="spark-3.5.1-bin-hadoop3"
export TF_VAR_aws_java_sdk="aws-java-sdk-bundle-1.12.262"
export TF_VAR_hadoop_aws="hadoop-aws-3.3.4"

# Only need to change if eventLog is enabled.
export TF_VAR_spark_log_bucket="Placeholder"  