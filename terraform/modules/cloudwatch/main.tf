resource "aws_cloudwatch_log_group" "default_log_group" {
  count             = var.log_group_name == "" ? 1 : 0
  name              = "/aws/lambda/event-router"
  retention_in_days = 1
}

locals {
  target_log_group = var.log_group_name != "" ? var.log_group_name : aws_cloudwatch_log_group.default_log_group[0].name
}


resource "aws_lambda_permission" "cloudwatch_lambda" {
  statement_id  = "cloudwatch-log-subscription"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "logs.${var.region}.amazonaws.com"
  source_arn    = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:${local.target_log_group}:*"
}

resource "aws_cloudwatch_log_subscription_filter" "cloudwatch_lambda" {
  depends_on      = [aws_lambda_permission.cloudwatch_lambda]
  name            = "cloudwatch-loki-shipper"
  log_group_name  = local.target_log_group
  filter_pattern  = ""
  destination_arn = var.lambda_function_arn
}

resource "aws_cloudwatch_log_group" "shipper_logs" {
  name              = "/aws/lambda/cloudwatch-loki-tailscale-shipper"
  retention_in_days = 1

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "cloudwatch_loki_policy" {
  role       = var.lambda_role_name
  policy_arn = var.lambda_policy_arn
}

resource "aws_iam_role_policy_attachment" "vpc_access_policy" {
  role       = var.lambda_role_name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
