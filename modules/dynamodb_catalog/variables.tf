variable "table_name" {
  description = "DynamoDB table name."
  type        = string
}

variable "gsi_name" {
  description = "Global Secondary Index name for name-based queries."
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources."
  type        = map(string)
  default     = {}
}
