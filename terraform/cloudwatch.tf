resource "aws_cloudwatch_log_group" "events-router" {
  name              = "/aws/lambda/events-router"
  retention_in_days = 1
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
