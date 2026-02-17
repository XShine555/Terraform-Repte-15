module "catalog_table" {
  source = "./modules/dynamodb_catalog"

  table_name = var.table_name
  gsi_name   = var.gsi_name
  tags       = var.tags
}

data "aws_caller_identity" "current" {}

locals {
  labrole_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
}

module "catalog_api" {
  source = "./modules/catalog_api"

  table_name      = module.catalog_table.table_name
  gsi_name        = module.catalog_table.gsi_name
  lambda_role_arn = local.labrole_arn
  lambda_name     = var.lambda_name
  api_name        = var.api_name
  api_stage_name  = var.api_stage_name
  lambda_timeout  = var.lambda_timeout
  lambda_memory   = var.lambda_memory
  tags            = var.tags
}
