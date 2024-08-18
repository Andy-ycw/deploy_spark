variable "key_path" {}
variable "iam_role" {}
variable "region" {}
variable "subnet_cidr" {}
variable "ec2_ami" {}
variable "ec2_master" {}
variable "ec2_slave" {}
variable "pkg_bucket" {}
variable "spark_log_bucket" {}
variable "jdk_name" {}
variable "spark_name" {}
variable "aws_java_sdk" {}
variable "hadoop_aws" {}
variable spark_driver_memory {}
variable spark_driver_core {}
variable spark_executor_memory {}
variable spark_executor_core {}
variable spark_executor_num {}


resource "aws_key_pair" "my_key" {
  key_name   = "my_key"
  public_key = file(var.key_path)
}

/*
Network resource provision
- VPC
- Subnet
- Security Group
*/
# Define the provider
provider "aws" {
  region = var.region
}

# Use the default network 
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default" {
  vpc_id     = data.aws_vpc.default.id
  cidr_block = var.subnet_cidr
}

# SG Config for Spark nodes
resource "aws_security_group" "spark_sg" {
  vpc_id = data.aws_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 4040
    to_port     = 4040
    protocol    = "tcp"
    cidr_blocks = [var.subnet_cidr]
  }

  ingress {
    from_port   = 7077
    to_port     = 7077
    protocol    = "tcp"
    cidr_blocks = [var.subnet_cidr]
  }
  
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.subnet_cidr]
  }

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = [var.subnet_cidr]
  }


  # Allowing traffic within the Spark Cluster.
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [var.subnet_cidr]
  }

  tags = {
    Name = "spark_sg"
  }
}


/* 
EC2 instance provision
- Role
- Instance profile 
- Instance specs
*/
# Get the configured role for the ec2 instance profile
data "aws_iam_role" "ec2_as_spark_node" {
  name = var.iam_role
}

# Create a instance profile
resource "aws_iam_instance_profile" "ec2_as_spark_profile" {
  name = "ec2_as_spark_profile"
  role = data.aws_iam_role.ec2_as_spark_node.name
}

resource "local_file" "rendered_template" {
  filename = "./.confidential/test_user_data.sh"
  content = templatefile("user_data.sh.tpl", 
    {
      jdk_name    = var.jdk_name
      spark_name  = var.spark_name
      aws_java_sdk = var.aws_java_sdk
      hadoop_aws = var.hadoop_aws
      pkg_bucket  = var.pkg_bucket
      spark_log_bucket = var.spark_log_bucket
      spark_driver_memory   = var.spark_driver_memory
      spark_driver_core     = var.spark_driver_core
      spark_executor_memory = var.spark_executor_memory
      spark_executor_core   = var.spark_executor_core
      node = "master"
      master_ip = "PlaceHolder"
    }
  )
}

# Define the EC2 instances
# resource "aws_instance" "bastion" {
#   ami           = var.ec2_ami
#   instance_type = var.ec2_master
#   key_name      = aws_key_pair.my_key.key_name
#   subnet_id     = data.aws_subnet.default.id
#   security_groups = [aws_security_group.spark_sg.id]

#   iam_instance_profile = aws_iam_instance_profile.ec2_as_spark_profile.name
#   # user_data = data.template_file.user_data.rendered
#   user_data = templatefile("user_data.sh.tpl", 
#     {
#       jdk_name    = var.jdk_name
#       spark_name  = var.spark_name
#       aws_java_sdk = var.aws_java_sdk
#       hadoop_aws = var.hadoop_aws
#       pkg_bucket  = var.pkg_bucket
#       spark_log_bucket = var.spark_log_bucket
#       spark_driver_memory   = var.spark_driver_memory
#       spark_driver_core     = var.spark_driver_core
#       spark_executor_memory = var.spark_executor_memory
#       spark_executor_core   = var.spark_executor_core
#       node = "bastion"
#       master_ip = "PlaceHolder"
#     }
#   )

#   metadata_options {
#     http_tokens = "optional"  # Use "optional" if you want to allow IMDSv1
#     http_put_response_hop_limit = 2
#     http_endpoint = "enabled"
#   }
  
#   tags = {
#     Name = "bastion"
#   }
# }

# resource "aws_instance" "spark_master" {
#   ami           = var.ec2_ami
#   instance_type = var.ec2_master
#   key_name      = aws_key_pair.my_key.key_name
#   subnet_id     = data.aws_subnet.default.id
#   security_groups = [aws_security_group.spark_sg.id]

#   iam_instance_profile = aws_iam_instance_profile.ec2_as_spark_profile.name
#   # user_data = data.template_file.user_data.rendered
#   user_data = templatefile("user_data.sh.tpl", 
#     {
#       jdk_name    = var.jdk_name
#       spark_name  = var.spark_name
#       aws_java_sdk = var.aws_java_sdk
#       hadoop_aws = var.hadoop_aws
#       pkg_bucket  = var.pkg_bucket
#       spark_log_bucket = var.spark_log_bucket
#       spark_driver_memory   = var.spark_driver_memory
#       spark_driver_core     = var.spark_driver_core
#       spark_executor_memory = var.spark_executor_memory
#       spark_executor_core   = var.spark_executor_core
#       node = "master"
#       master_ip = "PlaceHolder"
#     }
#   )

#   metadata_options {
#     http_tokens = "optional"  # Use "optional" if you want to allow IMDSv1
#     http_put_response_hop_limit = 2
#     http_endpoint = "enabled"
#   }
  
#   tags = {
#     Name = "spark-master"
#   }
# }

# resource "aws_instance" "spark_slave" {
#   count = var.spark_executor_num
#   ami           = var.ec2_ami
#   instance_type = var.ec2_slave
#   key_name      = aws_key_pair.my_key.key_name
#   subnet_id     = data.aws_subnet.default.id
#   security_groups = [aws_security_group.spark_sg.id]

#   iam_instance_profile = aws_iam_instance_profile.ec2_as_spark_profile.name
#   # user_data = data.template_file.user_data.rendered
#   user_data = templatefile("user_data.sh.tpl", 
#     {
#       jdk_name    = var.jdk_name
#       spark_name  = var.spark_name
#       aws_java_sdk = var.aws_java_sdk
#       hadoop_aws = var.hadoop_aws
#       pkg_bucket  = var.pkg_bucket
#       spark_log_bucket = var.spark_log_bucket
#       spark_driver_memory   = var.spark_driver_memory
#       spark_driver_core     = var.spark_driver_core
#       spark_executor_memory = var.spark_executor_memory
#       spark_executor_core   = var.spark_executor_core
#       node = "slave"
#       master_ip = aws_instance.spark_master.private_ip
#     }
#   )

#   metadata_options {
#     http_tokens = "optional"  # Use "optional" if you want to allow IMDSv1
#     http_put_response_hop_limit = 2
#     http_endpoint = "enabled"
#   }
  
#   tags = {
#     Name = "spark-slave"
#   }
# }