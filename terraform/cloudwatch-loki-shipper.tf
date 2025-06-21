locals {
  name_prefix_shipper = "ship-"
}

resource "aws_lambda_function" "cloudwatch-loki-shipper" {
  s3_bucket     = "ins-cloudwatch-loki-shipper"
  s3_key        = "cloudwatch-loki-shipper.zip"
  function_name = "cloudwatch-loki-shipper"
  role          = aws_iam_role.cloudwatch-loki-shipper.arn
  handler       = "loki-shipper.lambda_handler"
  memory_size   = "128"
  runtime       = "python3.9" # Updated from python3.6 which is deprecated
  timeout       = "600"

  environment {
    variables = {
      LOKI_ENDPOINT          = "http://loki-home-egress.tailf106f.ts.net:3100"
      LOG_LABELS             = "classname,logger_name"
      LOG_TEMPLATE           = "level=$level | $message"
      LOG_TEMPLATE_VARIABLES = "level,message"
      LOG_IGNORE_NON_JSON    = "true"
    }
  }

  vpc_config {
    subnet_ids         = module.vpc.private_subnets # Use private subnets for better security
    security_group_ids = [aws_security_group.lambda_egress.id]
  }
}

# Create a specific security group for Lambda egress
resource "aws_security_group" "lambda_egress" {
  name_prefix = "${local.name_prefix_shipper}lambda-egress-"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 3100
    to_port     = 3100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Or restrict to your cluster CIDR
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

# Rest of your existing resources remain the same
resource "aws_lambda_permission" "cloudwatch-loki-shipper" {
  statement_id  = "cloudwatch-loki-shipper"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudwatch-loki-shipper.arn
  principal     = "logs.${var.region}.amazonaws.com"
  source_arn    = aws_cloudwatch_log_group.events-router.arn
}

resource "aws_cloudwatch_log_subscription_filter" "cloudwatch-loki-shipper" {
  depends_on      = [aws_lambda_permission.cloudwatch-loki-shipper]
  name            = "cloudwatch-loki-shipper"
  log_group_name  = aws_cloudwatch_log_group.events-router.name
  filter_pattern  = ""
  destination_arn = aws_lambda_function.cloudwatch-loki-shipper.arn
}

resource "aws_cloudwatch_log_group" "cloudwatch-loki-shipper" {
  name              = "/aws/lambda/cloudwatch-loki-shipper"
  retention_in_days = 1
}

resource "aws_iam_role_policy_attachment" "cloudwatch-loki-shipper" {
  role       = aws_iam_role.cloudwatch-loki-shipper.name
  policy_arn = aws_iam_policy.cloudwatch-loki-shipper.arn
}

resource "aws_iam_role_policy_attachment" "cloudwatch-loki-shipper-vpc-policy" {
  role       = aws_iam_role.cloudwatch-loki-shipper.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role" "cloudwatch-loki-shipper" {
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

resource "aws_iam_policy" "cloudwatch-loki-shipper" {
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
