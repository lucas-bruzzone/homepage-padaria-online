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
# LAMBDA OUTPUTS
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

output "lambda_execution_role_arn" {
  description = "ARN da IAM role para execução das Lambdas"
  value       = aws_iam_role.lambda_execution_role.arn
}