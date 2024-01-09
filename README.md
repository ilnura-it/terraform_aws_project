# AWS Infrastructure with Terraform

This Terraform project automates the deployment of a basic AWS infrastructure. It includes:

## VPC and Subnets

- Creates a Virtual Private Cloud (VPC).
- Defines public and private subnets across multiple availability zones.

## Internet Gateway and Route Table

- Attaches an Internet Gateway to the VPC.
- Configures a route table for public and private subnets.

## Security Groups

- Sets up security groups for EC2 instances and an Application Load Balancer (ALB).

## EC2 Instances

- Launches an EC2 instance with specified AMI, instance type, and security group.

## Autoscaling Group and ALB

- Configures an Autoscaling Group for high availability.
- Creates an Application Load Balancer to distribute traffic to EC2 instances.

## S3 Bucket

- Establishes an S3 bucket with versioning and lifecycle configuration.

## Usage

1. Clone the repository.
2. Customize variables in `variables.tf` to fit your requirements.
3. Run `terraform init` and `terraform apply` to deploy the infrastructure.

## Cleanup

To destroy the infrastructure when done, run:

```bash
terraform destroy
