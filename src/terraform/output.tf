# ===================================
# WEBSITE OUTPUTS
# ===================================

output "https_website_url" {
  description = "URL HTTPS do website via API Gateway"
  value       = aws_apigatewayv2_api.website_api.api_endpoint
}

output "website_endpoint" {
  description = "Website endpoint HTTP (S3)"
  value       = "http://${aws_s3_bucket_website_configuration.frontend.website_endpoint}"
}

output "bucket_name" {
  description = "Nome do bucket S3"
  value       = aws_s3_bucket.frontend.id
}

# ===================================
# API GATEWAY OUTPUTS
# ===================================

output "api_gateway_url" {
  description = "URL do API Gateway para APIs"
  value       = aws_apigatewayv2_api.padaria_api.api_endpoint
}

# ===================================
# RDS OUTPUTS
# ===================================

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.padaria_postgres.endpoint
}

output "database_name" {
  description = "Database name"
  value       = aws_db_instance.padaria_postgres.db_name
}

output "database_username" {
  description = "Database username"
  value       = aws_db_instance.padaria_postgres.username
}

output "database_password" {
  description = "Database password"
  value       = random_password.db_password.result
  sensitive   = true
}

# ===================================
# DEPLOYMENT INFO
# ===================================

output "deployment_info" {
  description = "Informações de deployment"
  value = {
    region      = var.aws_region
    environment = var.environment
    project     = var.project_name
    https_url   = aws_apigatewayv2_api.website_api.api_endpoint
  }
}