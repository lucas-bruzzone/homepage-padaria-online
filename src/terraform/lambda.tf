# ===================================
# IAM ROLE PARA LAMBDA FUNCTIONS
# ===================================

resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.project_name}-lambda-execution-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_execution_role.name
}

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
  role          = aws_iam_role.lambda_execution_role.arn
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
  role          = aws_iam_role.lambda_execution_role.arn
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