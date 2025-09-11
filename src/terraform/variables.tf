variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, prod)"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}