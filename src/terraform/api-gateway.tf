# ===================================
# API GATEWAY HTTP API
# ===================================

resource "aws_apigatewayv2_api" "padaria_api" {
  name          = "${var.project_name}-api-${var.environment}"
  protocol_type = "HTTP"
  description   = "API Gateway para sistema da padaria"

  cors_configuration {
    allow_credentials = false
    allow_headers     = ["content-type", "x-amz-date", "authorization", "x-api-key"]
    allow_methods     = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_origins     = ["*"]
    max_age           = 86400
  }
}

# ===================================
# STAGES
# ===================================

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.padaria_api.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }
}

# ===================================
# LAMBDA INTEGRATIONS
# ===================================

# Integração Python Lambda
resource "aws_apigatewayv2_integration" "python_lambda" {
  api_id           = aws_apigatewayv2_api.padaria_api.id
  integration_type = "AWS_PROXY"

  connection_type      = "INTERNET"
  description          = "Python Lambda integration"
  integration_method   = "POST"
  integration_uri      = aws_lambda_function.python_lambda.invoke_arn
  passthrough_behavior = "WHEN_NO_MATCH"
}

# Integração Node.js Lambda
resource "aws_apigatewayv2_integration" "nodejs_lambda" {
  api_id           = aws_apigatewayv2_api.padaria_api.id
  integration_type = "AWS_PROXY"

  connection_type      = "INTERNET"
  description          = "Node.js Lambda integration"
  integration_method   = "POST"
  integration_uri      = aws_lambda_function.nodejs_lambda.invoke_arn
  passthrough_behavior = "WHEN_NO_MATCH"
}

# ===================================
# ROUTES
# ===================================

# Rotas Python Lambda
resource "aws_apigatewayv2_route" "python_get" {
  api_id    = aws_apigatewayv2_api.padaria_api.id
  route_key = "GET /python"
  target    = "integrations/${aws_apigatewayv2_integration.python_lambda.id}"
}

resource "aws_apigatewayv2_route" "python_post" {
  api_id    = aws_apigatewayv2_api.padaria_api.id
  route_key = "POST /python"
  target    = "integrations/${aws_apigatewayv2_integration.python_lambda.id}"
}

# Rotas Node.js Lambda
resource "aws_apigatewayv2_route" "nodejs_get" {
  api_id    = aws_apigatewayv2_api.padaria_api.id
  route_key = "GET /nodejs"
  target    = "integrations/${aws_apigatewayv2_integration.nodejs_lambda.id}"
}

resource "aws_apigatewayv2_route" "nodejs_post" {
  api_id    = aws_apigatewayv2_api.padaria_api.id
  route_key = "POST /nodejs"
  target    = "integrations/${aws_apigatewayv2_integration.nodejs_lambda.id}"
}

# Rotas específicas do sistema da padaria
resource "aws_apigatewayv2_route" "produtos_get" {
  api_id    = aws_apigatewayv2_api.padaria_api.id
  route_key = "GET /produtos"
  target    = "integrations/${aws_apigatewayv2_integration.python_lambda.id}"
}

resource "aws_apigatewayv2_route" "pedidos_post" {
  api_id    = aws_apigatewayv2_api.padaria_api.id
  route_key = "POST /pedidos"
  target    = "integrations/${aws_apigatewayv2_integration.nodejs_lambda.id}"
}

# ===================================
# LAMBDA PERMISSIONS
# ===================================

resource "aws_lambda_permission" "python_lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.python_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.padaria_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "nodejs_lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.nodejs_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.padaria_api.execution_arn}/*/*"
}

# ===================================
# CLOUDWATCH LOGS
# ===================================

resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/${var.project_name}-api-${var.environment}"
  retention_in_days = 14
}