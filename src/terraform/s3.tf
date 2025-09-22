# ===================================
# S3 BUCKET PARA ARMAZENAR ARQUIVOS ESTÁTICOS
# ===================================

resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-frontend-${var.environment}"
}

# Não precisa mais de configuração de website, pois será servido via Lambda
resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bucket privado - Lambda vai acessar via IAM
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Como estamos usando LabRole, não podemos criar uma nova role
# O Lambda vai usar LabRole que já tem permissões S3