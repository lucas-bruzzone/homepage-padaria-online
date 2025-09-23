# ===================================
# S3 OUTPUTS
# ===================================

output "website_endpoint" {
  description = "Website endpoint URL"
  value       = aws_s3_bucket_website_configuration.frontend.website_endpoint
}

output "website_domain" {
  description = "Website domain"
  value       = aws_s3_bucket_website_configuration.frontend.website_domain
}

output "bucket_name" {
  description = "Nome do bucket S3"
  value       = aws_s3_bucket.frontend.id
}

output "bucket_arn" {
  description = "ARN do bucket S3"
  value       = aws_s3_bucket.frontend.arn
}

# ===================================
# LAMBDA OUTPUTS (ORIGINAIS)
# ===================================

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
# API GATEWAY OUTPUTS (ORIGINAL)
# ===================================

output "api_gateway_url" {
  description = "URL do API Gateway para APIs"
  value       = aws_apigatewayv2_api.padaria_api.api_endpoint
}

# ===================================
# HTTPS WEBSITE OUTPUTS (NOVO)
# ===================================

output "https_website_url" {
  description = "🔒 URL HTTPS do website via API Gateway"
  value       = aws_apigatewayv2_api.website_api.api_endpoint
}

output "static_server_lambda_name" {
  description = "Nome da função Lambda do servidor estático"
  value       = aws_lambda_function.static_server.function_name
}

output "static_server_lambda_arn" {
  description = "ARN da função Lambda do servidor estático"
  value       = aws_lambda_function.static_server.arn
}

output "website_api_id" {
  description = "ID da API Gateway do website"
  value       = aws_apigatewayv2_api.website_api.id
}

# ===================================
# INFORMAÇÕES GERAIS
# ===================================

output "account_id" {
  description = "Account ID sendo utilizada"
  value       = data.aws_caller_identity.current.account_id
}

output "deployment_info" {
  description = "Informações de deployment"
  value = {
    region       = var.aws_region
    environment  = var.environment
    project_name = var.project_name
    http_url     = "http://${aws_s3_bucket_website_configuration.frontend.website_endpoint}"
    https_url    = aws_apigatewayv2_api.website_api.api_endpoint
    bucket_name  = aws_s3_bucket.frontend.id
  }
}