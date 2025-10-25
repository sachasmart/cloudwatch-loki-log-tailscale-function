module "vpc" {
  source = "./modules/vpc"

  name_prefix          = local.name_prefix_shipper
  vpc_cidr             = "10.0.0.0/16"
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24"]
  availability_zones   = ["${var.region}a", "${var.region}b"]
}


module "bucket" {
  source      = "./modules/bucket"
  bucket_name = "ins-cloudwatch-loki-tailscale-shipper"
  environment = "staging"
}

module "cloudwatch_log_subscription" {
  source = "./modules/cloudwatch"

  region               = var.region
  log_group_names      = var.log_groups
  lambda_function_name = aws_lambda_function.cloudwatch-loki-tailscale-shipper.function_name
  lambda_function_arn  = aws_lambda_function.cloudwatch-loki-tailscale-shipper.arn
  lambda_role_name     = aws_iam_role.cloudwatch-loki-tailscale-shipper.name
  lambda_policy_arn    = aws_iam_policy.cloudwatch-loki-tailscale-shipper.arn
}
