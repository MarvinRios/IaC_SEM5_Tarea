variable "environment" {
  description = "Nombre del entorno"
  type        = string
}

variable "name_prefix" {
  description = "Prefijo para nombrar recursos"
  type        = string
}

variable "sqs_queue_arn" {
  description = "ARN de la cola SQS que recibirá notificaciones de S3"
  type        = string
}

variable "sqs_queue_policy_ready" {
  description = "Dependencia: política de SQS que permite a S3 enviar mensajes"
  type        = any
  default     = null
}
