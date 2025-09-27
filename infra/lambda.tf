locals {
  name_prefix_shipper = "cloudwatch-loki-tailscale-shipper-"
}

resource "aws_lambda_function" "cloudwatch-loki-tailscale-shipper" {
  function_name = "cloudwatch-loki-tailscale-shipper"
  role          = aws_iam_role.cloudwatch-loki-tailscale-shipper.arn
  image_uri     = "${local.aws_ecr_url}/${aws_ecr_repository.ecr.name}:latest"
  package_type  = "Image"

  handler     = "main.lambda_handler"
  memory_size = "128"
  runtime     = "python3.12"
  timeout     = "600"


  environment {
    variables = {
      LOG_LOKI_ENDPOINT      = "${var.loki_endpoint}"
      TAILSCALE_AUTHKEY      = var.tailscale_auth_key
      LOG_LABELS             = "classname,logger_name"
      LOG_TEMPLATE           = "level=$level | $message"
      LOG_TEMPLATE_VARIABLES = "level,message"
      LOG_IGNORE_NON_JSON    = "false"
    }
  }

  vpc_config {
    subnet_ids         = module.vpc.private_subnets
    security_group_ids = [aws_security_group.lambda_egress.id]
  }
  lifecycle {
    ignore_changes = [runtime, handler]
  }
  depends_on = [module.bucket]
}
