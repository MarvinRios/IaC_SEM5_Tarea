# ---------- Empaquetar código Lambda ----------
data "archive_file" "upload_lambda" {
  type        = "zip"
  source_dir  = "${path.root}/../../lambda/upload"
  output_path = "${path.module}/dist/upload_lambda.zip"
}

data "archive_file" "crop_lambda" {
  type        = "zip"
  source_dir  = "${path.root}/../../lambda/crop"
  output_path = "${path.module}/dist/crop_lambda.zip"
}

# ============================================================
# IAM — UPLOAD LAMBDA
# ============================================================

resource "aws_iam_role" "upload_lambda" {
  name = "${var.name_prefix}-upload-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = {
    Name = "${var.name_prefix}-upload-lambda-role"
  }
}

# Permisos básicos de Lambda (CloudWatch Logs)
resource "aws_iam_role_policy_attachment" "upload_basic" {
  role       = aws_iam_role.upload_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Permisos de VPC (crear ENIs en subnets privadas)
resource "aws_iam_role_policy_attachment" "upload_vpc" {
  role       = aws_iam_role.upload_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Política personalizada: solo PutObject en uploads/
resource "aws_iam_role_policy" "upload_s3" {
  name = "${var.name_prefix}-upload-s3-policy"
  role = aws_iam_role.upload_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "PutObjectUploadsOnly"
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "${var.s3_bucket_arn}/uploads/*"
      }
    ]
  })
}

# ============================================================
# IAM — CROP LAMBDA
# ============================================================

resource "aws_iam_role" "crop_lambda" {
  name = "${var.name_prefix}-crop-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = {
    Name = "${var.name_prefix}-crop-lambda-role"
  }
}

resource "aws_iam_role_policy_attachment" "crop_basic" {
  role       = aws_iam_role.crop_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "crop_vpc" {
  role       = aws_iam_role.crop_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "crop_s3_sqs" {
  name = "${var.name_prefix}-crop-s3-sqs-policy"
  role = aws_iam_role.crop_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "GetObjectFromUploads"
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "${var.s3_bucket_arn}/uploads/*"
      },
      {
        Sid      = "PutObjectToProcessed"
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "${var.s3_bucket_arn}/processed/*"
      },
      {
        Sid    = "SQSOperations"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = var.sqs_queue_arn
      }
    ]
  })
}

# ============================================================
# LAMBDA: upload-lambda
# ============================================================

resource "aws_lambda_function" "upload" {
  function_name = "${var.name_prefix}-upload"
  description   = "Recibe imágenes via API Gateway y las sube a S3"

  filename         = data.archive_file.upload_lambda.output_path
  source_code_hash = data.archive_file.upload_lambda.output_base64sha256
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  memory_size      = var.upload_memory
  timeout          = 30
  role             = aws_iam_role.upload_lambda.arn

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.upload_sg_id]
  }

  environment {
    variables = {
      S3_BUCKET     = var.s3_bucket_id
      UPLOAD_PREFIX = "uploads"
      ENVIRONMENT   = var.environment
    }
  }

  tags = {
    Name = "${var.name_prefix}-upload"
  }

  depends_on = [
    aws_iam_role_policy_attachment.upload_basic,
    aws_iam_role_policy_attachment.upload_vpc,
  ]
}

resource "aws_cloudwatch_log_group" "upload" {
  name              = "/aws/lambda/${aws_lambda_function.upload.function_name}"
  retention_in_days = 14

  tags = {
    Name = "${var.name_prefix}-upload-logs"
  }
}

# ============================================================
# LAMBDA: crop-lambda
# ============================================================

resource "aws_lambda_function" "crop" {
  function_name = "${var.name_prefix}-crop"
  description   = "Descarga imagen de S3, recorta 40x40 circular PNG y guarda en processed/"

  filename         = data.archive_file.crop_lambda.output_path
  source_code_hash = data.archive_file.crop_lambda.output_base64sha256
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  memory_size      = var.crop_memory
  timeout          = 60
  role             = aws_iam_role.crop_lambda.arn

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.crop_sg_id]
  }

  environment {
    variables = {
      S3_BUCKET          = var.s3_bucket_id
      UPLOAD_PREFIX      = "uploads"
      PROCESSED_PREFIX   = "processed"
      ENVIRONMENT        = var.environment
    }
  }

  tags = {
    Name = "${var.name_prefix}-crop"
  }

  depends_on = [
    aws_iam_role_policy_attachment.crop_basic,
    aws_iam_role_policy_attachment.crop_vpc,
  ]
}

resource "aws_cloudwatch_log_group" "crop" {
  name              = "/aws/lambda/${aws_lambda_function.crop.function_name}"
  retention_in_days = 14

  tags = {
    Name = "${var.name_prefix}-crop-logs"
  }
}

# ============================================================
# EVENT SOURCE MAPPING: SQS → crop-lambda
# ============================================================

resource "aws_lambda_event_source_mapping" "sqs_to_crop" {
  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.crop.arn

  batch_size                         = 5
  maximum_batching_window_in_seconds = 5

  function_response_types = ["ReportBatchItemFailures"]

  depends_on = [aws_iam_role_policy.crop_s3_sqs]
}
