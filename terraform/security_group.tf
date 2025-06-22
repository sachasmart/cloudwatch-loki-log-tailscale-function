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
