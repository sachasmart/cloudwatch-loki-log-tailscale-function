locals {
  name_prefix_shipper = "cloudwatch-loki-tailscale-shipper-"
}

resource "null_resource" "lambda_build" {
  provisioner "local-exec" {
    command = "${path.module}/../build.sh"
  }

  triggers = {
    always_run = timestamp()
  }
}



resource "aws_s3_object" "lambda_zip" {
  bucket     = module.bucket.bucket
  key        = "${var.environment}/cloudwatch-loki-tailscale-shipper.zip"
  source     = data.archive_file.lambda_package.output_path
  etag       = filemd5(data.archive_file.lambda_package.output_path)
  depends_on = [module.bucket]
}



resource "aws_lambda_function" "cloudwatch-loki-tailscale-shipper" {
  s3_bucket     = module.bucket.bucket
  s3_key        = "${var.environment}/cloudwatch-loki-tailscale-shipper.zip"
  function_name = "cloudwatch-loki-tailscale-shipper"
  role          = aws_iam_role.cloudwatch-loki-tailscale-shipper.arn
  handler       = "loki-shipper.lambda_handler"
  memory_size   = "128"
  runtime       = "python3.9"
  timeout       = "600"

  environment {
    variables = {
      LOKI_ENDPOINT          = "https://${var.loki_endpoint}"
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
