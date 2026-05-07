resource "aws_apigatewayv2_api" "main" {
  name          = "${var.name_prefix}-api"
  protocol_type = "HTTP"
  description   = "Image Processor API — entorno ${var.environment}"

  cors_configuration {
    allow_origins = var.cors_allow_origins
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization"]
    max_age       = 300
  }

  tags = { Name = "${var.name_prefix}-api" }
}

# ---------- CloudWatch Log Group — access logs ----------
resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/apigateway/${var.name_prefix}"
  retention_in_days = 14
  tags              = { Name = "${var.name_prefix}-apigw-logs" }
}

# ---------- Stage: $default con auto-deploy ----------
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      errorMessage   = "$context.error.message"
    })
  }

  default_route_settings {
    throttling_rate_limit  = var.throttling_rate_limit
    throttling_burst_limit = var.throttling_burst_limit
  }

  tags = { Name = "${var.name_prefix}-api-stage-default" }
}

# ---------- Integración: API Gateway → upload-lambda ----------
resource "aws_apigatewayv2_integration" "upload" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.upload_lambda_invoke_arn
  payload_format_version = "2.0"
}

# ---------- Ruta: POST /upload ----------
resource "aws_apigatewayv2_route" "upload" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /upload"
  target    = "integrations/${aws_apigatewayv2_integration.upload.id}"
}

# ---------- Permiso: API Gateway puede invocar upload-lambda ----------
resource "aws_lambda_permission" "apigw_upload" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.upload_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*/upload"
}

# ---------- IAM Role para que API Gateway escriba en CloudWatch ----------
resource "aws_iam_role" "apigw_cloudwatch" {
  name = "${var.name_prefix}-apigw-cw-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "apigateway.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "apigw_cloudwatch" {
  role       = aws_iam_role.apigw_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = aws_iam_role.apigw_cloudwatch.arn
}
