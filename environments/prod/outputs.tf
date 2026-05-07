output "api_upload_url" {
  description = "URL para subir imágenes — POST a esta URL"
  value       = module.api_gateway.upload_url
}

output "s3_bucket_name" {
  description = "Nombre del bucket S3"
  value       = module.storage.bucket_name
}

output "sqs_queue_url" {
  description = "URL de la cola SQS"
  value       = module.queuing.queue_url
}

output "vpc_id" {
  description = "ID del VPC"
  value       = module.networking.vpc_id
}

output "cost_reminder" {
  description = "Recordatorio de costos activos"
  value       = "DEV: NAT Gateway DESHABILITADO. SQS Interface Endpoint activo en 1 AZ (~$7/mes)."
}
