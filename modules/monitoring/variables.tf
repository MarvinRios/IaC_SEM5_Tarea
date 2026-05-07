variable "environment" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "dlq_name" {
  description = "Nombre de la Dead-Letter Queue para la métrica de CloudWatch"
  type        = string
}

variable "alarm_email" {
  description = "Email para recibir alertas de la DLQ (dejar vacío para no suscribirse)"
  type        = string
  default     = ""
}
