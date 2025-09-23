# ===================================
# S3 BUCKET PARA ARMAZENAR ARQUIVOS ESTÁTICOS
# ===================================

resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-frontend-${var.environment}"
}

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

# ===================================
# UPLOAD DOS ARQUIVOS ESTÁTICOS VIA TERRAFORM
# ===================================

# Upload do index.html
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "index.html"
  source       = "${path.module}/../frontend/index.html"
  content_type = "text/html; charset=utf-8"
  etag         = filemd5("${path.module}/../frontend/index.html")

  depends_on = [aws_s3_bucket.frontend]
}

# Upload do sobre.html
resource "aws_s3_object" "sobre_html" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "sobre.html"
  source       = "${path.module}/../frontend/sobre.html"
  content_type = "text/html; charset=utf-8"
  etag         = filemd5("${path.module}/../frontend/sobre.html")

  depends_on = [aws_s3_bucket.frontend]
}

# Upload do styles.css
resource "aws_s3_object" "styles_css" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "styles.css"
  source       = "${path.module}/../frontend/styles.css"
  content_type = "text/css; charset=utf-8"
  etag         = filemd5("${path.module}/../frontend/styles.css")

  depends_on = [aws_s3_bucket.frontend]
}

# Upload do script.js
resource "aws_s3_object" "script_js" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "script.js"
  source       = "${path.module}/../frontend/script.js"
  content_type = "application/javascript; charset=utf-8"
  etag         = filemd5("${path.module}/../frontend/script.js")

  depends_on = [aws_s3_bucket.frontend]
}

# ===================================
# POLÍTICA IAM PARA LAMBDA ACESSAR S3
# ===================================

resource "aws_iam_role_policy" "lambda_s3_access" {
  name = "${var.project_name}-lambda-s3-access-${var.environment}"
  role = "LabRole"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.frontend.arn,
          "${aws_s3_bucket.frontend.arn}/*"
        ]
      }
    ]
  })
}