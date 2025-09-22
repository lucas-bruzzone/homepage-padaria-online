# ===================================
# API GATEWAY OUTPUTS
# ===================================

output "api_gateway_url" {
  description = "URL do API Gateway (HTTPS)"
  value       = aws_apigatewayv2_api.padaria_api.api_endpoint
}

output "website_url" {
  description = "URL do website (via API Gateway HTTPS)"
  value       = aws_apigatewayv2_api.padaria_api.api_endpoint
}

# ===================================
# S3 OUTPUTS
# ===================================

output "bucket_name" {
  description = "Nome do bucket S3"
  value       = aws_s3_bucket.frontend.id
}

output "bucket_arn" {
  description = "ARN do bucket S3"
  value       = aws_s3_bucket.frontend.arn
}

# ===================================
# LAMBDA OUTPUTS
# ===================================

output "frontend_lambda_function_name" {
  description = "Nome da função Lambda Frontend"
  value       = aws_lambda_function.frontend_lambda.function_name
}

output "frontend_lambda_arn" {
  description = "ARN da função Lambda Frontend"
  value       = aws_lambda_function.frontend_lambda.arn
}

output "python_lambda_function_name" {
  description = "Nome da função Lambda Python"
  value       = aws_lambda_function.python_lambda.function_name
}

output "python_lambda_arn" {
  description = "ARN da função Lambda Python"
  value       = aws_lambda_function.python_lambda.arn
}

output "nodejs_lambda_function_name" {
  description = "Nome da função Lambda Node.js"
  value       = aws_lambda_function.nodejs_lambda.function_name
}

output "nodejs_lambda_arn" {
  description = "ARN da função Lambda Node.js"
  value       = aws_lambda_function.nodejs_lambda.arn
}

# ===================================
# API GATEWAY DETAILS
# ===================================

output "api_gateway_id" {
  description = "ID do API Gateway"
  value       = aws_apigatewayv2_api.padaria_api.id
}

output "api_gateway_name" {
  description = "Nome do API Gateway"
  value       = aws_apigatewayv2_api.padaria_api.name
}

output "account_id" {
  description = "Account ID sendo utilizada"
  value       = data.aws_caller_identity.current.account_id
}

# ===================================
# ENDPOINTS DA API
# ===================================

output "api_endpoints" {
  description = "Endpoints disponíveis da API"
  value = {
    frontend   = "${aws_apigatewayv2_api.padaria_api.api_endpoint}/"
    python_api = "${aws_apigatewayv2_api.padaria_api.api_endpoint}/api/python"
    nodejs_api = "${aws_apigatewayv2_api.padaria_api.api_endpoint}/api/nodejs"
    produtos   = "${aws_apigatewayv2_api.padaria_api.api_endpoint}/api/produtos"
    pedidos    = "${aws_apigatewayv2_api.padaria_api.api_endpoint}/api/pedidos"
  }
}