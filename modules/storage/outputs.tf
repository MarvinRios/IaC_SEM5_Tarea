output "bucket_id" {
  description = "Nombre del bucket S3"
  value       = aws_s3_bucket.images.id
}

output "bucket_arn" {
  description = "ARN del bucket S3"
  value       = aws_s3_bucket.images.arn
}

output "bucket_name" {
  description = "Nombre completo del bucket (incluye sufijo)"
  value       = aws_s3_bucket.images.bucket
}
