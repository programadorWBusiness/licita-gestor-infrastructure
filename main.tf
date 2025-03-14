provider "aws" {
  region = var.aws_region
}

# -------------------------------
# 1) VPC & Networking
# -------------------------------
module "vpc" {
  source     = "./modules/vpc"
  cidr_block = var.vpc_cidr
}

# -------------------------------
# 2) ECS Cluster
# -------------------------------
module "ecs_cluster" {
  source      = "./modules/ecs-cluster"
  environment = var.environment
}

# -------------------------------
# 3) ECR Repositories
# -------------------------------
module "ecr" {
  source      = "./modules/ecr"
  environment = var.environment
  # You can pass var.backend_repo_name, etc. if needed
}

# -------------------------------
# 4) ECS Backend Service
#    WITHOUT ALB (public IP)
# -------------------------------
# We'll create a new Security Group that allows inbound from the internet.
# If you'd rather pass in an existing SG, you can do that.
resource "aws_security_group" "backend_public_sg" {
  name        = "${var.environment}-backend-public-sg"
  description = "Allow inbound HTTP (port ${var.backend_container_port}) from internet"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow inbound on container port"
    from_port   = var.backend_container_port
    to_port     = var.backend_container_port
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

module "backend_service" {
  source              = "./modules/ecs-service"
  cluster_id          = module.ecs_cluster.cluster_id
  service_name        = "backend-service"
  container_image     = module.ecr.backend_repository_url
  container_port      = var.backend_container_port

  # Run in the public subnets so we can assign a public IP (no ALB).
  subnets             = module.vpc.public_subnet_ids

  # Use the SG we just created that allows inbound from 0.0.0.0/0.
  security_groups     = [aws_security_group.backend_public_sg.id]
  execution_role_arn  = var.ecs_execution_role_arn
}

# -------------------------------
# 5) RDS Database
# -------------------------------
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

# -------------------------------
# 6) Amplify for Frontend
# -------------------------------
resource "aws_amplify_app" "frontend" {
  name        = var.amplify_app_name
  repository  = var.amplify_repo_url
  oauth_token = var.github_token

  # Automatically build on commits to the branch below:
  # enable_auto_build = true

  environment_variables = {
    # Example if your NestJS is on port 3000:
    # Provide a placeholder or set once you know the ECS task’s public IP
    NEST_APP_API_BASE_URL = "http://api.licitagestor.com.br"
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_amplify_branch" "frontend_main" {
  app_id      = aws_amplify_app.frontend.id
  branch_name = var.amplify_branch
}

resource "aws_amplify_domain_association" "frontend_domain" {
  app_id      = aws_amplify_app.frontend.id
  domain_name = "licitagestor.com.br"  # This domain must be in your Route53

    sub_domain {
    prefix      = "www"
    branch_name = aws_amplify_branch.frontend_main.branch_name
  }
}

# 1) Data source for your existing hosted zone:
data "aws_route53_zone" "this" {
  name         = "licitagestor.com.br."  # Must end with a dot
  private_zone = false
}

# 2) A record pointing to your ECS public IP:
resource "aws_route53_record" "api_backend" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "api.licitagestor.com.br"
  type    = "A"
  ttl     = 300
  records = ["0.0.0.0"]  # <--- The public IP found in ECS console
}
