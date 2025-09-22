# ===================================
# DATA SOURCE PARA LAB ROLE (AWS ACADEMY)
# ===================================

data "aws_caller_identity" "current" {}

# ===================================
# LAMBDA FUNCTION - PYTHON
# ===================================

data "archive_file" "python_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/python"
  output_path = "${path.module}/python_lambda.zip"
}

resource "aws_lambda_function" "python_lambda" {
  filename      = data.archive_file.python_lambda_zip.output_path
  function_name = "${var.project_name}-python-lambda-${var.environment}"
  role          = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  timeout       = 30

  source_code_hash = data.archive_file.python_lambda_zip.output_base64sha256

  environment {
    variables = {
      ENVIRONMENT  = var.environment
      PROJECT_NAME = var.project_name
    }
  }
}

# ===================================
# LAMBDA FUNCTION - NODE.JS
# ===================================

data "archive_file" "nodejs_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/nodejs"
  output_path = "${path.module}/nodejs_lambda.zip"
}

resource "aws_lambda_function" "nodejs_lambda" {
  filename      = data.archive_file.nodejs_lambda_zip.output_path
  function_name = "${var.project_name}-nodejs-lambda-${var.environment}"
  role          = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  timeout       = 30

  source_code_hash = data.archive_file.nodejs_lambda_zip.output_base64sha256

  environment {
    variables = {
      ENVIRONMENT  = var.environment
      PROJECT_NAME = var.project_name
    }
  }
}

# ===================================
# LAMBDA FUNCTION - FRONTEND
# ===================================

data "archive_file" "frontend_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/frontend"
  output_path = "${path.module}/frontend_lambda.zip"
}

resource "aws_lambda_function" "frontend_lambda" {
  filename      = data.archive_file.frontend_lambda_zip.output_path
  function_name = "${var.project_name}-frontend-${var.environment}"
  role          = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  timeout       = 30

  source_code_hash = data.archive_file.frontend_lambda_zip.output_base64sha256

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.frontend.id
    }
  }
}

# ===================================
# CLOUDWATCH LOG GROUPS
# ===================================

resource "aws_cloudwatch_log_group" "python_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.python_lambda.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "nodejs_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.nodejs_lambda.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "frontend_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.frontend_lambda.function_name}"
  retention_in_days = 14
}