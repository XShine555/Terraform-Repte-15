output "table_name" {
  description = "DynamoDB table name."
  value       = awscc_dynamodb_table.catalog.table_name
}

output "table_arn" {
  description = "DynamoDB table ARN."
  value       = awscc_dynamodb_table.catalog.arn
}

output "gsi_name" {
  description = "GSI name for name-based queries."
  value       = var.gsi_name
}
