output "sns_topic_arn" {
  description = "ARN del SNS Topic de alarmas"
  value       = aws_sns_topic.dlq_alarm.arn
}

output "dlq_alarm_arn" {
  description = "ARN de la alarma CloudWatch de la DLQ"
  value       = aws_cloudwatch_metric_alarm.dlq_messages.arn
}
