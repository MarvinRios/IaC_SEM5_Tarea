# ---------- VPC ----------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true   
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

# ---------- Internet Gateway ----------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.name_prefix}-igw" }
}

# ---------- Public Subnets ----------
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.name_prefix}-public-${var.availability_zones[count.index]}"
    Tier = "public"
  }
}

# ---------- Private Subnets ----------
resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "${var.name_prefix}-private-${var.availability_zones[count.index]}"
    Tier = "private"
  }
}

# ---------- Elastic IPs para NAT ----------
resource "aws_eip" "nat" {
  count      = var.enable_nat_gateway ? var.nat_gateway_count : 0
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]
  tags       = { Name = "${var.name_prefix}-eip-nat-${count.index}" }
}

# ---------- NAT Gateways ----------
resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? var.nat_gateway_count : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  depends_on    = [aws_internet_gateway.main]
  tags          = { Name = "${var.name_prefix}-nat-${count.index}" }
}

# ---------- Route Table — Public ----------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "${var.name_prefix}-rt-public" }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ---------- Route Tables — Private ----------
resource "aws_route_table" "private" {
  count  = length(var.private_subnets)
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.name_prefix}-rt-private-${var.availability_zones[count.index]}" }
}

resource "aws_route" "private_nat" {
  count                  = var.enable_nat_gateway ? length(var.private_subnets) : 0
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[min(count.index, var.nat_gateway_count - 1)].id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}


resource "aws_security_group" "upload_lambda" {
  name        = "${var.name_prefix}-sg-upload-lambda"
  description = "SG upload-lambda: sin inbound, outbound solo a VPC endpoints"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "${var.name_prefix}-sg-upload-lambda" }
  lifecycle { create_before_destroy = true }
}

resource "aws_security_group" "crop_lambda" {
  name        = "${var.name_prefix}-sg-crop-lambda"
  description = "SG crop-lambda: sin inbound, outbound solo a VPC endpoints"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "${var.name_prefix}-sg-crop-lambda" }
  lifecycle { create_before_destroy = true }
}

resource "aws_security_group" "vpce_sqs" {
  name        = "${var.name_prefix}-sg-vpce-sqs"
  description = "SG VPC Endpoint SQS: inbound 443 desde lambdas"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "${var.name_prefix}-sg-vpce-sqs" }
  lifecycle { create_before_destroy = true }
}


# upload-lambda → S3 Gateway Endpoint
resource "aws_security_group_rule" "upload_egress_s3" {
  type              = "egress"
  security_group_id = aws_security_group.upload_lambda.id
  description       = "HTTPS hacia S3 Gateway Endpoint"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [aws_vpc_endpoint.s3.prefix_list_id]
}

# upload-lambda → SQS Interface Endpoint
resource "aws_security_group_rule" "upload_egress_sqs" {
  type                     = "egress"
  security_group_id        = aws_security_group.upload_lambda.id
  description              = "HTTPS hacia SQS Interface Endpoint"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.vpce_sqs.id
}

# crop-lambda → S3 Gateway Endpoint
resource "aws_security_group_rule" "crop_egress_s3" {
  type              = "egress"
  security_group_id = aws_security_group.crop_lambda.id
  description       = "HTTPS hacia S3 Gateway Endpoint"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [aws_vpc_endpoint.s3.prefix_list_id]
}

# crop-lambda → SQS Interface Endpoint
resource "aws_security_group_rule" "crop_egress_sqs" {
  type                     = "egress"
  security_group_id        = aws_security_group.crop_lambda.id
  description              = "HTTPS hacia SQS Interface Endpoint"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.vpce_sqs.id
}

# vpce-sqs ← upload-lambda
resource "aws_security_group_rule" "vpce_ingress_upload" {
  type                     = "ingress"
  security_group_id        = aws_security_group.vpce_sqs.id
  description              = "TCP 443 desde upload-lambda"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.upload_lambda.id
}

# vpce-sqs ← crop-lambda
resource "aws_security_group_rule" "vpce_ingress_crop" {
  type                     = "ingress"
  security_group_id        = aws_security_group.vpce_sqs.id
  description              = "TCP 443 desde crop-lambda"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.crop_lambda.id
}

# ============================================================
# VPC ENDPOINTS
# ============================================================

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = aws_route_table.private[*].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowImagesBucketOnly"
      Effect    = "Allow"
      Principal = "*"
      Action    = ["s3:GetObject", "s3:PutObject"]
      Resource  = "${var.s3_bucket_arn}/*"
    }]
  })

  tags = { Name = "${var.name_prefix}-vpce-s3" }
}

# ---------- SQS Interface Endpoint ----------
resource "aws_vpc_endpoint" "sqs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.sqs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = slice(aws_subnet.private[*].id, 0, var.sqs_endpoint_az_count)
  security_group_ids  = [aws_security_group.vpce_sqs.id]
  tags                = { Name = "${var.name_prefix}-vpce-sqs" }
}
