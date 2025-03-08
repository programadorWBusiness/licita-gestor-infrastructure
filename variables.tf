variable "aws_region" {
  description = "AWS region to deploy in"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# ECR repository names
variable "backend_repo_name" {
  description = "ECR repository name for the backend"
  type        = string
  default     = "licita-gestor-backend"
}

variable "frontend_repo_name" {
  description = "ECR repository name for the frontend"
  type        = string
  default     = "licita-gestor-frontend"
}

# Container port settings
variable "backend_container_port" {
  description = "Port on which the backend container listens"
  type        = number
  default     = 3000
}

variable "frontend_container_port" {
  description = "Port on which the frontend container listens"
  type        = number
  default     = 3000
}

# Security group IDs for ECS services (set these as needed)
variable "backend_security_groups" {
  description = "List of security group IDs for the backend ECS service"
  type        = list(string)
  default     = []
}

variable "frontend_security_groups" {
  description = "List of security group IDs for the frontend ECS service"
  type        = list(string)
  default     = []
}

# Database settings
variable "db_engine" {
  description = "Database engine (e.g., postgres, mysql)"
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "Version of the database engine"
  type        = string
  default     = "13.4"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage (in GB) for the database"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "db_security_groups" {
  description = "Security groups for the RDS instance"
  type        = list(string)
  default     = []
}

variable "environment" {
  description = "The deployment environment (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "ecs_execution_role_arn" {
  description = "ARN of the ECS task execution role used for pulling images from ECR"
  type        = string
}
