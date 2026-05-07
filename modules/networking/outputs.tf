output "vpc_id" {
  description = "ID del VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs de las subnets públicas"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs de las subnets privadas"
  value       = aws_subnet.private[*].id
}

output "upload_lambda_sg_id" {
  description = "ID del Security Group de upload-lambda"
  value       = aws_security_group.upload_lambda.id
}

output "crop_lambda_sg_id" {
  description = "ID del Security Group de crop-lambda"
  value       = aws_security_group.crop_lambda.id
}

output "nat_gateway_ids" {
  description = "IDs de los NAT Gateways (vacío si enable_nat_gateway = false)"
  value       = aws_nat_gateway.main[*].id
}

output "s3_endpoint_id" {
  description = "ID del VPC Endpoint de S3"
  value       = aws_vpc_endpoint.s3.id
}

output "sqs_endpoint_id" {
  description = "ID del VPC Endpoint de SQS"
  value       = aws_vpc_endpoint.sqs.id
}
