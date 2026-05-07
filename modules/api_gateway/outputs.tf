output "api_endpoint" {
  description = "URL base del API Gateway"
  value       = aws_apigatewayv2_api.main.api_endpoint
}

output "api_id" {
  description = "ID del API Gateway"
  value       = aws_apigatewayv2_api.main.id
}

output "upload_url" {
  description = "URL completa del endpoint POST /upload"
  value       = "${aws_apigatewayv2_stage.default.invoke_url}/upload"
}
