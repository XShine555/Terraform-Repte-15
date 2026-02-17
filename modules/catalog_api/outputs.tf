output "invoke_url" {
  description = "Invoke URL for the REST API."
  value       = "https://${aws_api_gateway_rest_api.catalog.id}.execute-api.${data.aws_region.current.region}.amazonaws.com/${aws_api_gateway_stage.catalog.stage_name}"
}
