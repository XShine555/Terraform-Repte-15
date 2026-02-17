resource "awscc_dynamodb_table" "catalog" {
  table_name   = var.table_name
  billing_mode = "PAY_PER_REQUEST"

  attribute_definitions = [
    {
      attribute_name = "product_id"
      attribute_type = "S"
    },
    {
      attribute_name = "name"
      attribute_type = "S"
    }
  ]

  key_schema = jsonencode([
    {
      AttributeName = "product_id"
      KeyType       = "HASH"
    }
  ])

  global_secondary_indexes = [
    {
      index_name = var.gsi_name
      key_schema = [
        {
          attribute_name = "name"
          key_type       = "HASH"
        }
      ]
      projection = {
        projection_type   = "INCLUDE"
        non_key_attributes = [
          "category",
          "price",
          "type",
          "status"
        ]
      }
    }
  ]

  tags = [
    for key, value in var.tags : {
      key   = key
      value = value
    }
  ]
}
