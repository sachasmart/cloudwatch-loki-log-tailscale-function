variable "log_group_names" {
  description = "List of CloudWatch log group names to subscribe to"
  type        = list(string)
  default     = []
}

variable "region" {
  description = "AWS Region"
  type        = string
}

variable "lambda_function_name" {
  type = string
}

variable "lambda_function_arn" {
  type = string
}

variable "lambda_role_name" {
  type = string
}

variable "lambda_policy_arn" {
  type = string
}
