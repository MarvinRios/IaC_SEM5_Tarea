variable "environment" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "s3_bucket_arn" {
  description = "ARN del bucket S3 (para la política que permite enviar mensajes)"
  type        = string
}
