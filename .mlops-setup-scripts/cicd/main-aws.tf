module "aws_create_sp" {
  source = "databricks/mlops-aws-project/databricks"
  providers = {
    databricks.staging = databricks.staging
    databricks.prod    = databricks.prod
  }
  service_principal_name       = "my-mlp-cicd"
  project_directory_path       = "/my-mlp"
  service_principal_group_name = "my-mlp-service-principals"
}

data "databricks_current_user" "staging_user" {
  provider = databricks.staging
}

provider "databricks" {
  alias = "staging_sp"
  host  = "https://dbc-6b886e20-c214.dev.databricks.com"
  token = module.aws_create_sp.staging_service_principal_token
}

provider "databricks" {
  alias = "prod_sp"
  host  = "https://dbc-ffe32c62-b9d1.dev.databricks.com"
  token = module.aws_create_sp.prod_service_principal_token
}

module "staging_workspace_cicd" {
  source = "./common"
  providers = {
    databricks = databricks.staging_sp
  }
  git_provider    = var.git_provider
  git_token       = var.git_token
  env             = "staging"
  github_repo_url = var.github_repo_url
}

module "prod_workspace_cicd" {
  source = "./common"
  providers = {
    databricks = databricks.prod_sp
  }
  git_provider    = var.git_provider
  git_token       = var.git_token
  env             = "prod"
  github_repo_url = var.github_repo_url
}

// We produce the service principal API tokens as output, to enable
// extracting their values and storing them as secrets in your CI system
//
// If using GitHub Actions, you can create new repo secrets through Terraform as well
// e.g. using https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_secret
output "STAGING_WORKSPACE_TOKEN" {
  value     = module.aws_create_sp.staging_service_principal_token
  sensitive = true
}

output "PROD_WORKSPACE_TOKEN" {
  value     = module.aws_create_sp.prod_service_principal_token
  sensitive = true
}
