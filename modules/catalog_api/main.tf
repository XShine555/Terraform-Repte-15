data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/build/catalog_lambda.zip"
}

data "aws_region" "current" {}

resource "aws_lambda_function" "catalog_api" {
  function_name    = var.lambda_name
  role             = var.lambda_role_arn
  handler          = "handler.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory

  environment {
    variables = {
      DDB_TABLE    = var.table_name
      DDB_GSI_NAME = var.gsi_name
    }
  }

  tags = var.tags
}

resource "aws_api_gateway_rest_api" "catalog" {
  name = var.api_name
}

resource "aws_api_gateway_resource" "products" {
  rest_api_id = aws_api_gateway_rest_api.catalog.id
  parent_id   = aws_api_gateway_rest_api.catalog.root_resource_id
  path_part   = "products"
}

resource "aws_api_gateway_resource" "product_id" {
  rest_api_id = aws_api_gateway_rest_api.catalog.id
  parent_id   = aws_api_gateway_resource.products.id
  path_part   = "{id}"
}

resource "aws_api_gateway_method" "products_get" {
  rest_api_id   = aws_api_gateway_rest_api.catalog.id
  resource_id   = aws_api_gateway_resource.products.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "products_post" {
  rest_api_id   = aws_api_gateway_rest_api.catalog.id
  resource_id   = aws_api_gateway_resource.products.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "product_get" {
  rest_api_id   = aws_api_gateway_rest_api.catalog.id
  resource_id   = aws_api_gateway_resource.product_id.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "product_put" {
  rest_api_id   = aws_api_gateway_rest_api.catalog.id
  resource_id   = aws_api_gateway_resource.product_id.id
  http_method   = "PUT"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "product_delete" {
  rest_api_id   = aws_api_gateway_rest_api.catalog.id
  resource_id   = aws_api_gateway_resource.product_id.id
  http_method   = "DELETE"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "products_get" {
  rest_api_id             = aws_api_gateway_rest_api.catalog.id
  resource_id             = aws_api_gateway_resource.products.id
  http_method             = aws_api_gateway_method.products_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.catalog_api.invoke_arn
}

resource "aws_api_gateway_integration" "products_post" {
  rest_api_id             = aws_api_gateway_rest_api.catalog.id
  resource_id             = aws_api_gateway_resource.products.id
  http_method             = aws_api_gateway_method.products_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.catalog_api.invoke_arn
}

resource "aws_api_gateway_integration" "product_get" {
  rest_api_id             = aws_api_gateway_rest_api.catalog.id
  resource_id             = aws_api_gateway_resource.product_id.id
  http_method             = aws_api_gateway_method.product_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.catalog_api.invoke_arn
}

resource "aws_api_gateway_integration" "product_put" {
  rest_api_id             = aws_api_gateway_rest_api.catalog.id
  resource_id             = aws_api_gateway_resource.product_id.id
  http_method             = aws_api_gateway_method.product_put.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.catalog_api.invoke_arn
}

resource "aws_api_gateway_integration" "product_delete" {
  rest_api_id             = aws_api_gateway_rest_api.catalog.id
  resource_id             = aws_api_gateway_resource.product_id.id
  http_method             = aws_api_gateway_method.product_delete.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.catalog_api.invoke_arn
}

resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowApiGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.catalog_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.catalog.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "catalog" {
  rest_api_id = aws_api_gateway_rest_api.catalog.id

  triggers = {
    redeploy = sha1(jsonencode([
      aws_api_gateway_integration.products_get.id,
      aws_api_gateway_integration.products_post.id,
      aws_api_gateway_integration.product_get.id,
      aws_api_gateway_integration.product_put.id,
      aws_api_gateway_integration.product_delete.id
    ]))
  }

  depends_on = [
    aws_api_gateway_integration.products_get,
    aws_api_gateway_integration.products_post,
    aws_api_gateway_integration.product_get,
    aws_api_gateway_integration.product_put,
    aws_api_gateway_integration.product_delete,
    aws_lambda_permission.apigw_invoke
  ]
}

resource "aws_api_gateway_stage" "catalog" {
  rest_api_id   = aws_api_gateway_rest_api.catalog.id
  deployment_id = aws_api_gateway_deployment.catalog.id
  stage_name    = var.api_stage_name
}
