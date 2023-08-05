main.tf
provider "aws" {
  region = var.aws_region
}

module "ecr" {
  source = "./ecr-repo-module"

  environments = var.environments
}

module "ecs_cluster" {
  source = "./ecs-cluster-module"

  vpc_id              = var.vpc_id
  subnet_ids          = var.subnet_ids
  ecs_instance_count  = var.ecs_instance_count
  ecs_instance_type   = var.ecs_instance_type
  ecr_repo_urls       = module.ecr.repository_urls
}
============================================================
variables.tf
variable "aws_region" {
  description = "AWS region for the resources"
}

variable "environments" {
  description = "List of environments for creating ECR repositories"
  type        = set(string)
}

variable "vpc_id" {
  description = "VPC ID where the ECS cluster will be deployed"
}

variable "subnet_ids" {
  description = "List of subnet IDs in which EC2 instances will be placed"
  type        = list(string)
}

variable "ecs_instance_count" {
  description = "Number of ECS instances to launch in the cluster"
  default     = 1
}

variable "ecs_instance_type" {
  description = "Instance type for the ECS instances"
  default     = "t2.micro"
}
========================================
outputs.tf
output "ecs_cluster_id" {
  description = "ID of the created ECS cluster"
  value       = module.ecs_cluster.ecs_cluster_id
}

output "ecs_service_arn" {
  description = "ARN of the created ECS service"
  value       = module.ecs_cluster.ecs_service_arn
}
========================
my-ecs-cluster/terraform.tfvars:

terraform.tfvars
aws_region = "us-west-2"
environments = ["dev", "staging", "production"]
vpc_id = "vpc-12345678"
subnet_ids = ["subnet-12345678", "subnet-87654321"]
ecs_instance_count = 2
ecs_instance_type = "t2.small"
=============================================================
my-ecs-cluster/ecr-repo-module/main.tf:


variable "environments" {
  description = "List of environments for creating ECR repositories"
  type        = set(string)
}

resource "aws_ecr_repository" "this" {
  for_each = var.environments

  name         = each.key
  image_tag_mutability = "MUTABLE"
}

output "repository_names" {
  value = aws_ecr_repository.this[*].name
}

output "repository_urls" {
  value = aws_ecr_repository.this[*].repository_url
}
==================================================================
my-ecs-cluster/ecr-repo-module/variables.tf:
variable "environments" {
  description = "List of environments for creating ECR repositories"
  type        = set(string)
}
================================================
my-ecs-cluster/ecr-repo-module/outputs.tf:

output "repository_names" {
  description = "Names of the created ECR repositories"
  value       = aws_ecr_repository.this[*].name
}

output "repository_urls" {
  description = "URLs of the created ECR repositories"
  value       = aws_ecr_repository.this[*].repository_url
}

================================================
my-ecs-cluster/ecs-cluster-module/main.tf:
variable "vpc_id" {
  description = "VPC ID where the ECS cluster will be deployed"
}

variable "subnet_ids" {
  description = "List of subnet IDs in which EC2 instances will be placed"
  type        = list(string)
}

variable "ecs_instance_count" {
  description = "Number of ECS instances to launch in the cluster"
  default     = 1
}

variable "ecs_instance_type" {
  description = "Instance type for the ECS instances"
  default     = "t2.micro"
}

variable "ecr_repo_urls" {
  description = "List of ECR repository URLs to pull Docker images from"
  type        = list(string)
}

resource "aws_security_group" "ecs_sg" {
  name_prefix = "ecs-sg-"
  vpc_id      = var.vpc_id

  # Add necessary security group rules here
}

resource "aws_launch_configuration" "ecs_lc" {
  name_prefix   = "ecs-lc-"
  image_id      = "ami-0123456789abcdef0" # Replace with your desired EC2 AMI ID
  instance_type = var.ecs_instance_type

  security_groups = [aws_security_group.ecs_sg.id]

  # Add other instance configurations like IAM instance profile, user data, etc.
}

resource "aws_autoscaling_group" "ecs_asg" {
  name                 = "ecs-asg"
  launch_configuration = aws_launch_configuration.ecs_lc.name
  min_size             = var.ecs_instance_count
  max_size             = var.ecs_instance_count
  desired_capacity     = var.ecs_instance_count
  vpc_zone_identifier  = var.subnet_ids
}

resource "aws_ecs_task_definition" "ecs_task" {
  family                = "my-task-family"
  container_definitions = file("task_definition.json")
  execution_role_arn    = aws_iam_role.ecs_task_role.arn
}

resource "aws_ecs_service" "ecs_service" {
  name            = "my-ecs-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.ecs_task.arn
  desired_count   = var.ecs_instance_count

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = [aws_security_group.ecs_sg.id]
  }
}

output "ecs_cluster_id" {
  description = "ID of the created ECS cluster"
  value       = aws_ecs_cluster.this.id
}

output "ecs_service_arn" {
  description = "ARN of the created ECS service"
  value       = aws_ecs_service.ecs_service.arn
}

=================================================
my-ecs-cluster/ecs-cluster-module/variables.tf:

variable "vpc_id" {
  description = "VPC ID where the ECS cluster will be deployed"
}

variable "subnet_ids" {
  description = "List of subnet IDs in which EC2 instances will be placed"
  type        = list(string)
}

variable "ecs_instance_count" {
  description = "Number of ECS instances to launch in the cluster"
  default     = 1
}

variable "ecs_instance_type" {
  description = "Instance type for the ECS instances"
====================================================================

