output "queue_arn" {
  description = "ARN de la cola SQS principal"
  value       = aws_sqs_queue.main.arn
}

output "queue_url" {
  description = "URL de la cola SQS principal"
  value       = aws_sqs_queue.main.url
}

output "queue_name" {
  description = "Nombre de la cola SQS principal"
  value       = aws_sqs_queue.main.name
}

output "dlq_arn" {
  description = "ARN de la Dead-Letter Queue"
  value       = aws_sqs_queue.dlq.arn
}

output "dlq_name" {
  description = "Nombre de la Dead-Letter Queue"
  value       = aws_sqs_queue.dlq.name
}

output "sqs_policy_id" {
  description = "ID de la política SQS (para dependencias de orden)"
  value       = aws_sqs_queue_policy.main.id
}
