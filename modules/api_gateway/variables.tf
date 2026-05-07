variable "environment" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "upload_lambda_invoke_arn" {
  description = "ARN de invocación de upload-lambda"
  type        = string
}

variable "upload_lambda_name" {
  description = "Nombre de la función upload-lambda (para el permiso)"
  type        = string
}

variable "throttling_rate_limit" {
  description = "Límite de solicitudes por segundo (diagrama: 10,000)"
  type        = number
  default     = 10000
}

variable "throttling_burst_limit" {
  description = "Límite de ráfaga de solicitudes"
  type        = number
  default     = 5000
}

variable "cors_allow_origins" {
  description = "Orígenes permitidos en CORS"
  type        = list(string)
  default     = ["*"]
}
