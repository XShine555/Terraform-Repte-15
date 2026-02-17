import base64
import decimal
import json
import os

import boto3
from boto3.dynamodb.conditions import Attr, Key

_TABLE_NAME = os.environ.get("DDB_TABLE")
_GSI_NAME = os.environ.get("DDB_GSI_NAME")

_dynamodb = boto3.resource("dynamodb")
_table = _dynamodb.Table(_TABLE_NAME)


def _decimal_to_json(value):
    if isinstance(value, decimal.Decimal):
        if value % 1 == 0:
            return int(value)
        return float(value)
    raise TypeError("Unsupported type")


def _response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "*",
            "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS"
        },
        "body": json.dumps(body, default=_decimal_to_json)
    }


def _parse_body(event):
    raw_body = event.get("body")
    if not raw_body:
        return {}
    if event.get("isBase64Encoded"):
        raw_body = base64.b64decode(raw_body).decode("utf-8")
    return json.loads(raw_body)


def _encode_token(last_key):
    if not last_key:
        return None
    payload = json.dumps(last_key, default=_decimal_to_json).encode("utf-8")
    return base64.urlsafe_b64encode(payload).decode("utf-8")


def _decode_token(token):
    if not token:
        return None
    try:
        raw = base64.urlsafe_b64decode(token.encode("utf-8")).decode("utf-8")
        return json.loads(raw)
    except (ValueError, json.JSONDecodeError):
        return None


def _get_price(value):
    if value is None:
        return None
    return decimal.Decimal(str(value))


def _list_products(params):
    limit = min(int(params.get("limit", "25")), 100)
    start_key = _decode_token(params.get("next"))

    name = params.get("name")
    category = params.get("category")
    min_price = _get_price(params.get("min_price"))
    max_price = _get_price(params.get("max_price"))

    filter_expr = None
    if category:
        filter_expr = Attr("category").eq(category)
    if min_price is not None:
        expr = Attr("price").gte(min_price)
        filter_expr = expr if filter_expr is None else filter_expr & expr
    if max_price is not None:
        expr = Attr("price").lte(max_price)
        filter_expr = expr if filter_expr is None else filter_expr & expr

    if name:
        query = {
            "IndexName": _GSI_NAME,
            "KeyConditionExpression": Key("name").eq(name),
            "Limit": limit
        }
        if start_key:
            query["ExclusiveStartKey"] = start_key
        if filter_expr is not None:
            query["FilterExpression"] = filter_expr
        response = _table.query(**query)
    else:
        scan = {"Limit": limit}
        if start_key:
            scan["ExclusiveStartKey"] = start_key
        if filter_expr is not None:
            scan["FilterExpression"] = filter_expr
        response = _table.scan(**scan)

    items = response.get("Items", [])
    next_token = _encode_token(response.get("LastEvaluatedKey"))

    return _response(200, {"items": items, "next": next_token})


def _create_product(event):
    body = _parse_body(event)
    product_id = body.get("id")
    name = body.get("name")
    price = body.get("price")

    if not product_id or not name or price is None:
        return _response(400, {"message": "id, name y price son obligatorios"})

    item = {
        "product_id": product_id,
        "name": name,
        "price": _get_price(price)
    }

    for field in ["category", "type", "status"]:
        if field in body:
            item[field] = body[field]

    _table.put_item(
        Item=item,
        ConditionExpression="attribute_not_exists(product_id)"
    )

    return _response(201, item)


def _get_product(product_id):
    response = _table.get_item(Key={"product_id": product_id})
    item = response.get("Item")
    if not item:
        return _response(404, {"message": "Producto no encontrado"})
    return _response(200, item)


def _update_product(product_id, event):
    body = _parse_body(event)
    allowed = {"name", "price", "category", "type", "status"}

    updates = {k: v for k, v in body.items() if k in allowed}
    if not updates:
        return _response(400, {"message": "No hay campos para actualizar"})

    expr_names = {}
    expr_values = {}
    parts = []

    for idx, (key, value) in enumerate(updates.items()):
        name_key = f"#f{idx}"
        value_key = f":v{idx}"
        expr_names[name_key] = key
        expr_values[value_key] = _get_price(value) if key == "price" else value
        parts.append(f"{name_key} = {value_key}")

    response = _table.update_item(
        Key={"product_id": product_id},
        UpdateExpression="SET " + ", ".join(parts),
        ExpressionAttributeNames=expr_names,
        ExpressionAttributeValues=expr_values,
        ReturnValues="ALL_NEW"
    )

    return _response(200, response.get("Attributes", {}))


def _delete_product(product_id):
    _table.delete_item(Key={"product_id": product_id})
    return _response(204, {})


def handler(event, context):
    method = event.get("httpMethod", "")
    resource = event.get("resource", "")

    if method == "OPTIONS":
        return _response(200, {"ok": True})

    if resource == "/products" and method == "GET":
        params = event.get("queryStringParameters") or {}
        return _list_products(params)

    if resource == "/products" and method == "POST":
        return _create_product(event)

    if resource == "/products/{id}":
        product_id = (event.get("pathParameters") or {}).get("id")
        if not product_id:
            return _response(400, {"message": "Falta el id"})

        if method == "GET":
            return _get_product(product_id)
        if method == "PUT":
            return _update_product(product_id, event)
        if method == "DELETE":
            return _delete_product(product_id)

    return _response(404, {"message": "Ruta no encontrada"})
