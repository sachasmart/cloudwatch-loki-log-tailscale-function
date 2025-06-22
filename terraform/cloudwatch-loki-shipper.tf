locals {
  name_prefix_shipper = "cloudwatch-loki-tailscale-shipper-"
}


resource "aws_s3_object" "lambda_zip" {
  bucket     = module.bucket.bucket
  key        = "${var.environment}/cloudwatch-loki-tailscale-shipper.zip"
  source     = "${path.module}/../cloudwatch-loki-shipper.zip"
  depends_on = [module.bucket]
}




resource "aws_lambda_function" "cloudwatch-loki-tailscale-shipper" {
  s3_bucket     = module.bucket.bucket
  s3_key        = "${var.environment}/cloudwatch-loki-tailscale-shipper.zip"
  function_name = "cloudwatch-loki-tailscale-shipper"
  role          = aws_iam_role.cloudwatch-loki-tailscale-shipper.arn
  handler       = "main.lambda_handler"
  memory_size   = "128"
  runtime       = "python3.12"
  timeout       = "600"


  environment {
    variables = {
      LOG_LOKI_ENDPOINT      = "https://${var.loki_endpoint}"
      LOG_LABELS             = "classname,logger_name"
      LOG_TEMPLATE           = "level=$level | $message"
      LOG_TEMPLATE_VARIABLES = "level,message"
      LOG_IGNORE_NON_JSON    = "true"
    }
  }

  vpc_config {
    subnet_ids         = module.vpc.private_subnets
    security_group_ids = [aws_security_group.lambda_egress.id]
  }
  depends_on = [module.bucket, aws_s3_object.lambda_zip]
}
