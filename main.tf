################################################
# Provider
################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}


provider "aws" {
  region = var.aws_region
}

################################################
# Locals
################################################

locals {
  tags = {
    Name        = "Inter.task"
    Terraform   = true
    Environment = var.environment
  }
}

################################################
# VPC
################################################

resource "aws_vpc" "basic_vpc" {
  cidr_block           = var.cidr_block
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  instance_tenancy     = "default"

  tags = local.tags
}

resource "aws_subnet" "public_subnet1" {
  vpc_id                  = aws_vpc.basic_vpc.id
  cidr_block              = var.cidr_block_pub1
  map_public_ip_on_launch = "true"
  availability_zone       = "us-east-1a"

  tags = local.tags
}

resource "aws_subnet" "public_subnet2" {
  vpc_id                  = aws_vpc.basic_vpc.id
  cidr_block              = var.cidr_block_pub2
  map_public_ip_on_launch = "true"
  availability_zone       = "us-east-1b"

  tags = local.tags
}

resource "aws_subnet" "private_subnet1" {
  vpc_id            = aws_vpc.basic_vpc.id
  cidr_block        = var.cidr_block_priv1
  availability_zone = "us-east-1a"

  tags = local.tags
}

resource "aws_subnet" "private_subnet2" {
  vpc_id            = aws_vpc.basic_vpc.id
  cidr_block        = var.cidr_block_priv2
  availability_zone = "us-east-1b"

  tags = local.tags
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.basic_vpc.id

  tags = local.tags
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.basic_vpc.id
  route {

    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = local.tags
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_subnet1.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public_subnet2.id
  route_table_id = aws_route_table.route_table.id
}


resource "aws_route_table_association" "private-subnet-A" {
  subnet_id      = aws_subnet.private_subnet1.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_route_table_association" "private-subnet-B" {
  subnet_id      = aws_subnet.private_subnet2.id
  route_table_id = aws_route_table.route_table.id
}

################################################
# Security Group for ec2
################################################

resource "aws_security_group" "ec2-sg" {
  name        = "allow_ssh"
  description = "Allow ssh inbound traffic"
  vpc_id      = aws_vpc.basic_vpc.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.my_ip
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

################################################
# Security Group for ALB
################################################
resource "aws_security_group" "alb-sg" {
  name        = "alb-sg"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.basic_vpc.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.my_ip
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
################################################
# EC2
################################################

resource "aws_instance" "ec2" {

  instance_type               = var.instance_type
  ami                         = var.ami_id
  key_name                    = data.aws_key_pair.my_key_pair.key_name
  monitoring                  = true
  vpc_security_group_ids      = [aws_security_group.ec2-sg.id]
  subnet_id                   = aws_subnet.public_subnet2.id
  associate_public_ip_address = true

  root_block_device {
    volume_size           = 20
    volume_type           = "gp2"
    delete_on_termination = true
  }

  tags = local.tags
}

################################################
# Launch template
################################################

resource "aws_launch_template" "task_lt" {
  name                   = "task_lt"
  image_id               = var.ami_id
  instance_type          = var.instance_type
  key_name               = data.aws_key_pair.my_key_pair.key_name
  vpc_security_group_ids = ["${aws_security_group.alb-sg.id}"]
  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      volume_size = 20
    }
  }

  user_data = filebase64("${path.module}/user_data.sh")
}


################################################
#Auto-Scaling Group
################################################

resource "aws_autoscaling_group" "task-asg" {
  name                = "task-asg"
  max_size            = 6
  min_size            = 2
  desired_capacity    = 2
  health_check_type   = "ELB"
  target_group_arns   = [aws_lb_target_group.tasktg.arn]
  vpc_zone_identifier = [aws_subnet.private_subnet1.id, aws_subnet.private_subnet2.id]
  launch_template {
    id      = aws_launch_template.task_lt.id
    version = aws_launch_template.task_lt.latest_version
  }
}

################################################
#Application Load Balancer
################################################

resource "aws_lb" "task-alb" {
  name               = "task-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-sg.id]
  subnets            = [aws_subnet.public_subnet1.id, aws_subnet.public_subnet2.id]
  tags               = local.tags
}

################################################
# Listener for Application Load Balancer
################################################

resource "aws_lb_listener" "task_listener" {
  load_balancer_arn = aws_lb.task-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tasktg.arn
  }
}

################################################
# Listener rule for Application Load Balancer
################################################

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.task_listener.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }
  # Distribute requests to 1 or more target groups
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tasktg.arn
  }
}

################################################
# Target Group
################################################

resource "aws_lb_target_group" "tasktg" {
  name     = "intask"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.basic_vpc.id
}

resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = aws_autoscaling_group.task-asg.id
  lb_target_group_arn    = aws_lb_target_group.tasktg.arn
}

################################################
# S3 Bucket
################################################

resource "aws_s3_bucket" "task_bucket" {
  bucket = "my-tf-task-bucket-ilya001"

  tags = local.tags
}

resource "aws_s3_bucket_versioning" "task_bucket" {
  bucket = aws_s3_bucket.task_bucket.bucket

  versioning_configuration {
    status = "Enabled"
  }

}

resource "aws_s3_bucket_lifecycle_configuration" "life_cycle-config1" {
  bucket = aws_s3_bucket.task_bucket.bucket

  rule {
    id = "Images"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }

  rule {
    id = "Logs"
    status = "Enabled"

    expiration {
      days = 90
    }
  }
}
