variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
}

variable "table_name" {
  description = "DynamoDB table name."
  type        = string
  default     = "products_catalog"
}

variable "gsi_name" {
  description = "Global Secondary Index name for name-based queries."
  type        = string
  default     = "gsi_name"
}

variable "lambda_name" {
  description = "Lambda function name."
  type        = string
  default     = "catalog-crud"
}

variable "api_name" {
  description = "API Gateway REST API name."
  type        = string
  default     = "catalog-api"
}

variable "api_stage_name" {
  description = "API Gateway stage name."
  type        = string
  default     = "prod"
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds."
  type        = number
  default     = 10
}

variable "lambda_memory" {
  description = "Lambda memory size in MB."
  type        = number
  default     = 128
}

variable "tags" {
  description = "Tags to apply to resources."
  type        = map(string)
  default     = {}
}
