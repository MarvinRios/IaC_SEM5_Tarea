variable "environment" {
  description = "Nombre del entorno: dev, qa, prod"
  type        = string
}

variable "name_prefix" {
  description = "Prefijo para nombrar recursos"
  type        = string
}

variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block del VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "Lista de CIDRs para subnets públicas"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "Lista de CIDRs para subnets privadas"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "availability_zones" {
  description = "Lista de zonas de disponibilidad"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "enable_nat_gateway" {
  description = <<-EOT
    Si se crean NAT Gateways.
    COSTO: ~$32/mes por NAT Gateway + procesamiento de datos.
    Recomendado: false para DEV y QA (las Lambdas solo necesitan
    VPC Endpoints, no internet).
  EOT
  type        = bool
  default     = false
}

variable "nat_gateway_count" {
  description = "Número de NAT Gateways (1 para QA, 2 para PROD con HA)"
  type        = number
  default     = 1
}

variable "sqs_endpoint_az_count" {
  description = <<-EOT
    Número de AZs en las que se despliega el SQS Interface Endpoint.
    Costo: ~$7.20/mes por AZ.
    DEV: 1 AZ, QA: 1 AZ, PROD: 2 AZs
  EOT
  type        = number
  default     = 1
}

variable "s3_bucket_arn" {
  description = "ARN del bucket S3 de imágenes (para la política del Gateway Endpoint)"
  type        = string
}
