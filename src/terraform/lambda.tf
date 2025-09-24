# ===================================
# DATA SOURCE PARA LAB ROLE (AWS ACADEMY)
# ===================================

data "aws_caller_identity" "current" {}

# ===================================
resource "aws_security_group" "lambda_sg" {
  name_prefix = "${var.project_name}-lambda-${var.environment}"
  description = "Security group for Lambda functions"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-lambda-sg-${var.environment}"
  }
}

data "archive_file" "python_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/python"
  output_path = "${path.module}/python_lambda.zip"
}
# ===================================
# LAMBDA PYTHON COM RDS
# ===================================

resource "aws_lambda_function" "python_lambda" {
  filename      = data.archive_file.python_lambda_zip.output_path
  function_name = "${var.project_name}-python-lambda-${var.environment}"
  role          = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  timeout       = 30

  source_code_hash = data.archive_file.python_lambda_zip.output_base64sha256

  # VPC Configuration
  vpc_config {
    subnet_ids         = data.aws_subnets.default.ids
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      ENVIRONMENT  = var.environment
      PROJECT_NAME = var.project_name
      DB_HOST      = aws_db_instance.padaria_postgres.endpoint
      DB_PORT      = tostring(aws_db_instance.padaria_postgres.port)
      DB_NAME      = aws_db_instance.padaria_postgres.db_name
      DB_USERNAME  = aws_db_instance.padaria_postgres.username
      DB_PASSWORD  = random_password.db_password.result
    }
  }

  depends_on = [aws_db_instance.padaria_postgres]
}

# ===================================
# LAMBDA NODE.JS COM RDS
# ===================================

resource "aws_lambda_function" "nodejs_lambda" {
  filename      = data.archive_file.nodejs_lambda_zip.output_path
  function_name = "${var.project_name}-nodejs-lambda-${var.environment}"
  role          = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  timeout       = 30

  source_code_hash = data.archive_file.nodejs_lambda_zip.output_base64sha256

  # VPC Configuration
  vpc_config {
    subnet_ids         = data.aws_subnets.default.ids
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      ENVIRONMENT  = var.environment
      PROJECT_NAME = var.project_name
      DB_HOST      = aws_db_instance.padaria_postgres.endpoint
      DB_PORT      = tostring(aws_db_instance.padaria_postgres.port)
      DB_NAME      = aws_db_instance.padaria_postgres.db_name
      DB_USERNAME  = aws_db_instance.padaria_postgres.username
      DB_PASSWORD  = random_password.db_password.result
    }
  }

  depends_on = [aws_db_instance.padaria_postgres]
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