variable "log_group_name" {
  description = "Name of the existing CloudWatch log group to subscribe to. If not provided, a default one called event-router will be created"
  type        = string
  default     = ""
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
