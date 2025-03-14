# Licita Gestor Infrastructure


This repository manages the **Licita Gestor** infrastructure using [Terraform](https://www.terraform.io). We use GitHub Actions with OpenID Connect (OIDC) for secure, keyless CI/CD deployments, and a local `.env.local` file for development. This approach keeps sensitive credentials out of version control while ensuring consistency across environments.

## Table of Contents

- [Project Overview](#project-overview)
- [Prerequisites](#prerequisites)
- [Local Development](#local-development)
- [CI/CD with GitHub Actions](#cicd-with-github-actions)
- [Remote State Backend (Optional)](#remote-state-backend-optional)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## Project Overview

- **Terraform Modules:**
  The repository is organized into custom modules under the `modules/` directory (e.g., `vpc`, `ecs-cluster`, `ecs-service`, `rds`, and `ecr`).

- **Local Development:**
  Use a project-specific `.env.local` file (which is in `.gitignore`) to store your AWS credentials and sensitive variables for local Terraform operations.

- **CI/CD:**
  GitHub Actions uses OIDC to assume an IAM role for deployments, avoiding long-lived AWS keys in the pipeline.

## Prerequisites

- [Terraform 1.4+](https://www.terraform.io/downloads.html) installed locally.
- An AWS account with permissions to manage VPC, ECR, ECS, RDS, etc.
- GitHub Actions OIDC provider set up in AWS. See [GitHub's documentation](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-aws) for details.

## Local Development

For local development, create a `.env.local` file in the project root to hold your AWS credentials and other sensitive variables. **Ensure this file is listed in `.gitignore` so it isn’t committed.**

### Example `.env.local`

```bash
# .env.local (DO NOT COMMIT THIS FILE)
AWS_ACCESS_KEY_ID=YOUR_LOCAL_KEY
AWS_SECRET_ACCESS_KEY=YOUR_LOCAL_SECRET
AWS_DEFAULT_REGION=us-east-1

DB_PASSWORD=YOUR_DB_PASSWORD
ECS_EXECUTION_ROLE_ARN=arn:aws:iam::533267284248:role/CI-CD-FLOW
```

### Running Terraform Locally

1. **Source the Environment File:**

   ```bash
   source .env.local
   ```

2. **Run Terraform Commands:**

   ```bash
   terraform init
   terraform plan -var db_password="$DB_PASSWORD" -var ecs_execution_role_arn="$ECS_EXECUTION_ROLE_ARN"
   terraform apply -var db_password="$DB_PASSWORD" -var ecs_execution_role_arn="$ECS_EXECUTION_ROLE_ARN"
   ```

*Optional:* Create a helper script (e.g., `scripts/terraform_dev.sh`):

```bash
#!/usr/bin/env bash
set -e

source .env.local
terraform init
terraform plan -var db_password="$DB_PASSWORD" -var ecs_execution_role_arn="$ECS_EXECUTION_ROLE_ARN"
```

Make it executable with:

```bash
chmod +x scripts/terraform_dev.sh
```

Then run it with:

```bash
./scripts/terraform_dev.sh
```

## CI/CD with GitHub Actions

GitHub Actions automates testing and deployment when changes are pushed or pull requests are opened on the `main` branch.

### Example Workflow (`.github/workflows/terraform.yml`)

```yaml
name: Terraform CI/CD

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  terraform:
    permissions:
      id-token: write  # Needed for OIDC token generation
      contents: read
    runs-on: ubuntu-latest
    steps:
      - name: Check out repo
        uses: actions/checkout@v3

      - name: Set up Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.4.6

      - name: Configure AWS Credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: arn:aws:iam::533267284248:role/CI-CD-FLOW
          aws-region: us-east-1

      - name: Terraform init
        run: terraform init

      - name: Terraform plan
        run: terraform plan -input=false \
          -var db_password="${{ secrets.DB_PASSWORD }}" \
          -var ecs_execution_role_arn="${{ secrets.ECS_EXECUTION_ROLE_ARN }}"

      - name: Terraform apply
        if: github.event_name == 'push' && github.ref_name == 'main'
        run: terraform apply -auto-approve -input=false \
          -var db_password="${{ secrets.DB_PASSWORD }}" \
          -var ecs_execution_role_arn="${{ secrets.ECS_EXECUTION_ROLE_ARN }}"
```

### Setting Up Secrets in GitHub

1. In your GitHub repository, navigate to **Settings → Security → Secrets and variables → Actions**.
2. Add the following secrets:
   - `DB_PASSWORD` – your database password.
   - `ECS_EXECUTION_ROLE_ARN` – the ARN of your ECS execution role (if not provided via OIDC).

## Remote State Backend (Optional)

For collaboration and consistent state management, configure a remote state backend (e.g., S3 with DynamoDB for locking).

### Example Backend Configuration in `main.tf`

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "licita-gestor-infrastructure/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "your-terraform-lock-table"
    encrypt        = true
  }
}
```

After adding this configuration, run:

```bash
terraform init
```

to migrate your state.

## Troubleshooting

- **No valid credential sources found (Local):**
  Ensure you source your `.env.local` or have AWS credentials configured in your `~/.aws/credentials`.

- **ECR repository already exists:**
  If Terraform reports that an ECR repository already exists, import it using:
  ```bash
  terraform import module.ecr.aws_ecr_repository.backend dev-backend
  terraform import module.ecr.aws_ecr_repository.frontend dev-frontend
  ```

- **RDS engine version invalid:**
  Verify supported PostgreSQL versions in your region and update the `db_engine_version` variable accordingly.

- **Resource creation errors or timeouts:**
  Check IAM role policies, VPC subnet configurations, and ensure that your RDS DB subnet group spans at least two Availability Zones.

## License

This project is licensed under the [MIT License](LICENSE).

## Questions or Issues

If you encounter any issues or have questions, please open an issue on GitHub or contact the team.
