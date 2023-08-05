provider "aws" {
  region = "us-west-2" # Change this to your desired AWS region
}

# Create an ECS cluster
resource "aws_ecs_cluster" "this" {
  name = "my-ecs-cluster"
}

# Create an IAM role for the ECS task
resource "aws_iam_role" "ecs_task_role" {
  name = "my-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the required IAM policies to the ECS task role
resource "aws_iam_role_policy_attachment" "ecs_task_role_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_task_role.name
}

# Create a task definition for ECS
resource "aws_ecs_task_definition" "this" {
  family                = "my-task-family"
  container_definitions = file("task_definition.json")
  execution_role_arn    = aws_iam_role.ecs_task_role.arn
}

# Create an Auto Scaling Group (ASG) for EC2 instances in the ECS cluster
resource "aws_launch_configuration" "this" {
  name_prefix   = "my-ecs-instance"
  image_id      = "ami-0123456789abcdef0" # Replace with your desired EC2 AMI ID
  instance_type = "t2.micro" # Replace with your desired EC2 instance type

  # Add any other configurations like security groups, IAM instance profile, etc.
}

resource "aws_autoscaling_group" "this" {
  name                 = "my-ecs-asg"
  launch_configuration = aws_launch_configuration.this.name
  min_size             = 1
  max_size             = 3 # Change this as per your requirement
  desired_capacity     = 1
  vpc_zone_identifier  = ["subnet-12345678"] # Replace with your subnet ID(s)

  # Add any other configurations like load balancer attachment, tags, etc.
}

# Create an ECS service to run tasks in the cluster
resource "aws_ecs_service" "this" {
  name            = "my-ecs-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 2 # Number of tasks to run
  launch_type     = "EC2" # Use EC2 launch type
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent        = 200

  network_configuration {
    subnets         = ["subnet-12345678"] # Replace with your subnet ID(s)
    security_groups = ["sg-12345678"] # Replace with your security group ID(s)
  }
}
