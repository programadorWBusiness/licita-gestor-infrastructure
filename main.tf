provider "aws" {
  region = var.aws_region
}

# Create VPC and networking
module "vpc" {
  source     = "./modules/vpc"
  cidr_block = var.vpc_cidr
}

# Create ECS Cluster
module "ecs_cluster" {
  source      = "./modules/ecs-cluster"
  environment = var.environment

}

# Create ECR repositories for backend and optionally frontend images
module "ecr" {
  source      = "./modules/ecr"
  environment = var.environment
  # No need to pass in backend_repo_name or frontend_repo_name here
  # unless you decide to define them in the ECR module’s variables.
}

# Deploy Backend Service (NestJS) on ECS
module "backend_service" {
  source          = "./modules/ecs-service"
  cluster_id      = module.ecs_cluster.cluster_id
  service_name    = "backend-service"
  container_image = module.ecr.backend_repository_url  # Provided by ECR module
  container_port  = var.backend_container_port
  # Instead of private_subnets, reference public_subnets from your VPC module:
  subnets         = module.vpc.public_subnet_ids
  security_groups = var.backend_security_groups
}

# Optionally, deploy Frontend Service (NextJS) on ECS
module "frontend_service" {
  source          = "./modules/ecs-service"
  cluster_id      = module.ecs_cluster.cluster_id
  service_name    = "frontend-service"
  container_image = module.ecr.frontend_repository_url
  container_port  = var.frontend_container_port
  subnets         = module.vpc.public_subnet_ids
  security_groups = var.frontend_security_groups
}

# Create an RDS Database instance
module "rds" {
  source            = "./modules/rds"
  engine            = var.db_engine
  engine_version    = var.db_engine_version
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  db_name           = var.db_name
  username          = var.db_username
  password          = var.db_password
  subnets           = module.vpc.public_subnet_ids
  security_groups   = var.db_security_groups
}
