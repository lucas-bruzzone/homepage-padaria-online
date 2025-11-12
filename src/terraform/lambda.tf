data "aws_caller_identity" "current" {}

# ===================================
# LAMBDA LAYER - PSYCOPG2
# ===================================

module "psycopg2_layer" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 4.7"

  create_function = false
  create_layer    = true

  layer_name          = "${var.project_name}-psycopg2-${var.environment}"
  description         = "psycopg2 library for PostgreSQL connection"
  compatible_runtimes = ["python3.11"]
  runtime             = "python3.11"

  source_path = [
    {
      path             = "${path.module}/../lambda/layers/psycopg2"
      pip_requirements = true
      prefix_in_zip    = "python"
    }
  ]

  store_on_s3 = false
}

# ===================================
# SECURITY GROUP PARA LAMBDAS
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

# ===================================
# LAMBDA FUNCTION - PYTHON (COM PSYCOPG2 LAYER)
# ===================================

module "python_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 4.7"

  function_name = "${var.project_name}-python-lambda-${var.environment}"
  source_path   = "${path.module}/../lambda/python"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  timeout       = 30

  layers = [module.psycopg2_layer.lambda_layer_arn]

  vpc_subnet_ids         = data.aws_subnets.default.ids
  vpc_security_group_ids = [aws_security_group.lambda_sg.id]
  attach_network_policy  = true

  environment_variables = {
    ENVIRONMENT  = var.environment
    PROJECT_NAME = var.project_name
    DB_HOST      = aws_db_instance.padaria_postgres.endpoint
    DB_PORT      = tostring(aws_db_instance.padaria_postgres.port)
    DB_NAME      = aws_db_instance.padaria_postgres.db_name
    DB_USERNAME  = aws_db_instance.padaria_postgres.username
    DB_PASSWORD  = random_password.db_password.result
  }

  create_role = false
  lambda_role = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"

  store_on_s3 = false

  depends_on = [
    aws_db_instance.padaria_postgres,
    module.psycopg2_layer
  ]
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
# CLOUDWATCH LOGS
# ===================================

# Log group do Python Lambda é criado automaticamente pelo módulo

resource "aws_cloudwatch_log_group" "nodejs_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.nodejs_lambda.function_name}"
  retention_in_days = 14
}
