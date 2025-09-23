# ===================================
# LAMBDA PARA SERVIR ARQUIVOS ESTÁTICOS
# ===================================

data "archive_file" "static_server_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/static-server"
  output_path = "${path.module}/static-server.zip"
}

resource "aws_lambda_function" "static_server" {
  filename      = data.archive_file.static_server_zip.output_path
  function_name = "${var.project_name}-static-server-${var.environment}"
  role          = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  timeout       = 30

  source_code_hash = data.archive_file.static_server_zip.output_base64sha256

  environment {
    variables = {
      BUCKET_NAME  = aws_s3_bucket.frontend.id
      ENVIRONMENT  = var.environment
      PROJECT_NAME = var.project_name
    }
  }

  depends_on = [aws_s3_bucket.frontend]
}

# ===================================
# API GATEWAY HTTP API PARA WEBSITE
# ===================================

resource "aws_apigatewayv2_api" "website_api" {
  name          = "${var.project_name}-website-api-${var.environment}"
  protocol_type = "HTTP"
  description   = "API Gateway para servir website da padaria com HTTPS"

  cors_configuration {
    allow_credentials = false
    allow_headers     = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token"]
    allow_methods     = ["GET", "HEAD", "OPTIONS"]
    allow_origins     = ["*"]
    max_age           = 86400
  }

  tags = {
    Name = "${var.project_name}-website-api-${var.environment}"
  }
}

# ===================================
# STAGE PARA API GATEWAY
# ===================================

resource "aws_apigatewayv2_stage" "website_stage" {
  api_id      = aws_apigatewayv2_api.website_api.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.website_api_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      userAgent      = "$context.identity.userAgent"
    })
  }

  default_route_settings {
    detailed_metrics_enabled = true
    throttling_burst_limit   = 100
    throttling_rate_limit    = 50
  }

  tags = {
    Name = "${var.project_name}-website-stage-${var.environment}"
  }
}

# ===================================
# INTEGRAÇÃO COM LAMBDA
# ===================================

resource "aws_apigatewayv2_integration" "static_server_integration" {
  api_id           = aws_apigatewayv2_api.website_api.id
  integration_type = "AWS_PROXY"

  connection_type        = "INTERNET"
  description            = "Static server Lambda integration"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.static_server.invoke_arn
  passthrough_behavior   = "WHEN_NO_MATCH"
  payload_format_version = "2.0"
  timeout_milliseconds   = 30000
}

# ===================================
# ROTAS PARA SERVIR WEBSITE
# ===================================

# Rota para arquivos específicos (com extensão)
resource "aws_apigatewayv2_route" "static_files" {
  api_id    = aws_apigatewayv2_api.website_api.id
  route_key = "GET /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.static_server_integration.id}"
}

# Rota para a página inicial
resource "aws_apigatewayv2_route" "root_route" {
  api_id    = aws_apigatewayv2_api.website_api.id
  route_key = "GET /"
  target    = "integrations/${aws_apigatewayv2_integration.static_server_integration.id}"
}

# Rota OPTIONS para CORS
resource "aws_apigatewayv2_route" "options_route" {
  api_id    = aws_apigatewayv2_api.website_api.id
  route_key = "OPTIONS /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.static_server_integration.id}"
}

# ===================================
# PERMISSÕES LAMBDA
# ===================================

resource "aws_lambda_permission" "static_server_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.static_server.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.website_api.execution_arn}/*/*"
}

# ===================================
# CLOUDWATCH LOGS
# ===================================

resource "aws_cloudwatch_log_group" "website_api_logs" {
  name              = "/aws/apigateway/${var.project_name}-website-api-${var.environment}"
  retention_in_days = 14

  tags = {
    Name = "${var.project_name}-website-api-logs-${var.environment}"
  }
}

resource "aws_cloudwatch_log_group" "static_server_logs" {
  name              = "/aws/lambda/${aws_lambda_function.static_server.function_name}"
  retention_in_days = 14

  tags = {
    Name = "${var.project_name}-static-server-logs-${var.environment}"
  }
}