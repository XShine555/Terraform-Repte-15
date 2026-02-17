variable "table_name" {
  description = "DynamoDB table name."
  type        = string
}

variable "gsi_name" {
  description = "Global Secondary Index name for name-based queries."
  type        = string
}

variable "lambda_role_arn" {
  description = "Existing IAM role ARN for the Lambda."
  type        = string
}

variable "lambda_name" {
  description = "Lambda function name."
  type        = string
}

variable "api_name" {
  description = "API Gateway REST API name."
  type        = string
}

variable "api_stage_name" {
  description = "API Gateway stage name."
  type        = string
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds."
  type        = number
}

variable "lambda_memory" {
  description = "Lambda memory size in MB."
  type        = number
}

variable "tags" {
  description = "Tags to apply to resources."
  type        = map(string)
  default     = {}
}
