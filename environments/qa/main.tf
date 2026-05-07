# ============================================================
# ENTORNO: DEV
# ============================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }

}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "image-processor"
      ManagedBy   = "terraform"
      CostCenter  = "university"
    }
  }
}

locals {
  name_prefix = "image-processor-${var.environment}"
}

# ── 1. QUEUING 
module "queuing" {
  source = "../../modules/queuing"

  environment   = var.environment
  name_prefix   = local.name_prefix
  s3_bucket_arn = module.storage.bucket_arn
}

# ── 2. STORAGE ─────────────────────────────────────────────────────────────
module "storage" {
  source = "../../modules/storage"

  environment            = var.environment
  name_prefix            = local.name_prefix
  sqs_queue_arn          = module.queuing.queue_arn
  sqs_queue_policy_ready = module.queuing.sqs_policy_id
}

# ── 3. NETWORKING ──────────────────────────────────────────────────────────
module "networking" {
  source = "../../modules/networking"

  environment            = var.environment
  name_prefix            = local.name_prefix
  aws_region             = var.aws_region
  vpc_cidr               = var.vpc_cidr
  public_subnets         = var.public_subnets
  private_subnets        = var.private_subnets
  availability_zones     = var.availability_zones
  enable_nat_gateway     = var.enable_nat_gateway    
  nat_gateway_count      = var.nat_gateway_count
  sqs_endpoint_az_count  = var.sqs_endpoint_az_count 
  s3_bucket_arn          = module.storage.bucket_arn
}

# ── 4. COMPUTE ─────────────────────────────────────────────────────────────
module "compute" {
  source = "../../modules/compute"

  environment        = var.environment
  name_prefix        = local.name_prefix
  s3_bucket_id       = module.storage.bucket_id
  s3_bucket_arn      = module.storage.bucket_arn
  sqs_queue_arn      = module.queuing.queue_arn
  sqs_queue_url      = module.queuing.queue_url
  private_subnet_ids = module.networking.private_subnet_ids
  upload_sg_id       = module.networking.upload_lambda_sg_id
  crop_sg_id         = module.networking.crop_lambda_sg_id
  upload_memory      = var.upload_lambda_memory
  crop_memory        = var.crop_lambda_memory
}

# ── 5. API GATEWAY ─────────────────────────────────────────────────────────
module "api_gateway" {
  source = "../../modules/api_gateway"

  environment              = var.environment
  name_prefix              = local.name_prefix
  upload_lambda_invoke_arn = module.compute.upload_lambda_invoke_arn
  upload_lambda_name       = module.compute.upload_lambda_name
  throttling_rate_limit    = var.api_throttling_rate_limit
  throttling_burst_limit   = var.api_throttling_burst_limit
  cors_allow_origins       = var.cors_allow_origins
}

# ── 6. MONITORING ──────────────────────────────────────────────────────────
module "monitoring" {
  source = "../../modules/monitoring"

  environment = var.environment
  name_prefix = local.name_prefix
  dlq_name    = module.queuing.dlq_name
  alarm_email = var.alarm_email
}
