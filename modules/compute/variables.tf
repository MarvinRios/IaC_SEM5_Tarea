variable "environment" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "s3_bucket_id" {
  description = "Nombre/ID del bucket S3"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN del bucket S3"
  type        = string
}

variable "sqs_queue_arn" {
  description = "ARN de la cola SQS principal"
  type        = string
}

variable "sqs_queue_url" {
  description = "URL de la cola SQS principal"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs de las subnets privadas donde se despliegan las Lambdas"
  type        = list(string)
}

variable "upload_sg_id" {
  description = "ID del Security Group de upload-lambda"
  type        = string
}

variable "crop_sg_id" {
  description = "ID del Security Group de crop-lambda"
  type        = string
}

variable "upload_memory" {
  description = "Memoria en MB para upload-lambda (diagrama: 256 MB)"
  type        = number
  default     = 256
}

variable "crop_memory" {
  description = "Memoria en MB para crop-lambda (diagrama: 512 MB)"
  type        = number
  default     = 512
}
