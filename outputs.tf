output "catalog_table_name" {
  description = "Name of the DynamoDB catalog table."
  value       = module.catalog_table.table_name
}

output "catalog_table_arn" {
  description = "ARN of the DynamoDB catalog table."
  value       = module.catalog_table.table_arn
}

output "catalog_gsi_name" {
  description = "Name of the catalog table GSI."
  value       = module.catalog_table.gsi_name
}

output "catalog_api_invoke_url" {
  description = "Invoke URL for the catalog REST API."
  value       = module.catalog_api.invoke_url
}
