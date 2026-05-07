variable "environment" {
  description = "Nombre del entorno"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

# ── Networking ──────────────────────────────────────────────
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "enable_nat_gateway" {
  description = "Activar NAT Gateway — COSTO: ~$32/mes cada uno"
  type        = bool
  default     = false # DEV: false para ahorrar costos
}

variable "nat_gateway_count" {
  type    = number
  default = 1
}

variable "sqs_endpoint_az_count" {
  description = "AZs con SQS Interface Endpoint — COSTO: ~$7/mes por AZ"
  type        = number
  default     = 1 # DEV: 1 AZ
}

# ── Compute ─────────────────────────────────────────────────
variable "upload_lambda_memory" {
  type    = number
  default = 256
}

variable "crop_lambda_memory" {
  type    = number
  default = 512
}

# ── API Gateway ─────────────────────────────────────────────
variable "api_throttling_rate_limit" {
  type    = number
  default = 100 # Reducido para DEV
}

variable "api_throttling_burst_limit" {
  type    = number
  default = 50
}

variable "cors_allow_origins" {
  type    = list(string)
  default = ["*"]
}

# ── Monitoring ──────────────────────────────────────────────
variable "alarm_email" {
  description = "Email para alertas (dejar vacío si no se necesita)"
  type        = string
  default     = ""
}
