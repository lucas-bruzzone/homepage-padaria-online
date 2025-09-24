# ===================================
# RDS PostgreSQL Simples para AWS Academy
# ===================================

# Security Group para RDS
resource "aws_security_group" "rds_sg" {
  name_prefix = "${var.project_name}-rds-${var.environment}"
  description = "Security group for RDS PostgreSQL"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg-${var.environment}"
  }
}

# DB Subnet Group usando subnets padrão
data "aws_subnets" "default" {
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

resource "aws_db_subnet_group" "padaria_db_subnet_group" {
  name       = "${var.project_name}-db-subnet-${var.environment}"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = "${var.project_name}-db-subnet-${var.environment}"
  }
}

# Gera senha aleatória
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# Instância RDS PostgreSQL
resource "aws_db_instance" "padaria_postgres" {
  identifier = "${var.project_name}-postgres-${var.environment}"

  engine         = "postgres"
  engine_version = "17.4"
  instance_class = "db.t3.micro"

  db_name  = "padariadb"
  username = "postgres"
  password = random_password.db_password.result

  allocated_storage = 20
  storage_type      = "gp2"

  db_subnet_group_name   = aws_db_subnet_group.padaria_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false

  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false

  tags = {
    Name = "${var.project_name}-postgres-${var.environment}"
  }
}