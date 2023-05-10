#######################################################
# Global Variables
#######################################################
variable "aws_region" {
  description = "The AWS region to deploy EC2 instance"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "The Environment to deploy project"
  type        = string
  default     = "Dev"
}


#######################################################
# EC2 Variables
#######################################################
variable "ami_id" {
  description = "The AMI ID to create instance"
  type        = string
  default     = "ami-016eb5d644c333ccb"
}

variable "instance_type" {
  description = "The EC2 instance type to provision"
  type        = string
  default     = "t2.micro"
}

#######################################################
# VPC Variables
#######################################################

variable "cidr_block" {
  description = "The cidr_block to create VPC"
  type        = list(string)
  default     = ["10.1.0.0/16"]
}

variable "cidr_block_pub1" {
  description = "The cidr_block for public subnet 1"
  type        = list(string)
  default     = ["10.1.0.0/24"]
}

variable "cidr_block_pub2" {
  description = "The cidr_block for public subnet 2"
  type        = list(string)
  default     = ["10.1.1.0/24"]
}

variable "cidr_block_priv1" {
  description = "The cidr_block for private subnet 1"
  type        = list(string)
  default     = ["10.1.2.0/24"]
}

variable "cidr_block_priv2" {
  description = "The cidr_block for private subnet 2"
  type        = list(string)
  default     = ["10.1.3.0/24"]
}

variable "my_ip" {
  description = "My Ip address"
  type        = list(string)
  default     = ["208.78.41.90/32"]
}