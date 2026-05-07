# ---------- SNS Topic para notificaciones de alarma ----------
resource "aws_sns_topic" "dlq_alarm" {
  name = "${var.name_prefix}-dlq-alarm-topic"

  tags = {
    Name = "${var.name_prefix}-dlq-alarm-topic"
  }
}

resource "aws_sns_topic_subscription" "dlq_email" {
  count     = var.alarm_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.dlq_alarm.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# ---------- CloudWatch Alarm: DLQ tiene mensajes ----------
resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  alarm_name          = "${var.name_prefix}-dlq-messages-alarm"
  alarm_description   = "Hay mensajes en la DLQ de ${var.name_prefix} — revisar crop-lambda"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = var.dlq_name
  }

  alarm_actions = [aws_sns_topic.dlq_alarm.arn]
  ok_actions    = [aws_sns_topic.dlq_alarm.arn]

  tags = {
    Name = "${var.name_prefix}-dlq-alarm"
  }
}
