locals {
  name_prefix_shipper = "ship-"
}

resource "aws_lambda_function" "cloudwatch-loki-tailscale-shipper" {
  s3_bucket     = "ins-cloudwatch-loki-tailscale-shipper"
  s3_key        = "cloudwatch-loki-tailscale-shipper.zip"
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
}

resource "aws_security_group" "lambda_egress" {
  name_prefix = "${local.name_prefix_shipper}lambda-egress-"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 3100
    to_port     = 3100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow egress to Loki"
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS egress"
  }

  tags = {
    Name = "${local.name_prefix_shipper}lambda-egress"
  }
}

resource "aws_lambda_permission" "cloudwatch-loki-tailscale-shipper" {
  statement_id  = "cloudwatch-loki-tailscale-shipper"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudwatch-loki-tailscale-shipper.arn
  principal     = "logs.${var.region}.amazonaws.com"
  source_arn    = aws_cloudwatch_log_group.events-router.arn
}

resource "aws_cloudwatch_log_subscription_filter" "cloudwatch-loki-tailscale-shipper" {
  depends_on      = [aws_lambda_permission.cloudwatch-loki-tailscale-shipper]
  name            = "cloudwatch-loki-tailscale-shipper"
  log_group_name  = aws_cloudwatch_log_group.events-router.name
  filter_pattern  = ""
  destination_arn = aws_lambda_function.cloudwatch-loki-tailscale-shipper.arn
}

resource "aws_cloudwatch_log_group" "cloudwatch-loki-tailscale-shipper" {
  name              = "/aws/lambda/cloudwatch-loki-tailscale-shipper"
  retention_in_days = 1
}

resource "aws_iam_role_policy_attachment" "cloudwatch-loki-tailscale-shipper" {
  role       = aws_iam_role.cloudwatch-loki-tailscale-shipper.name
  policy_arn = aws_iam_policy.cloudwatch-loki-tailscale-shipper.arn
}

resource "aws_iam_role_policy_attachment" "cloudwatch-loki-tailscale-shipper-vpc-policy" {
  role       = aws_iam_role.cloudwatch-loki-tailscale-shipper.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role" "cloudwatch-loki-tailscale-shipper" {
  name_prefix = local.name_prefix_shipper
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      }
    ]
  })
}

resource "aws_iam_policy" "cloudwatch-loki-tailscale-shipper" {
  name_prefix = local.name_prefix_shipper
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
        Effect   = "Allow"
      },
      {
        Action = [
          "ec2:DescribeNetworkInterfaces",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:AttachNetworkInterface"
        ]
        Resource = "*"
        Effect   = "Allow"
      }
    ]
  })
}
