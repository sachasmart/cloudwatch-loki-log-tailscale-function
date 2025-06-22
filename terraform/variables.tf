variable "region" {
  description = "The AWS region where resources will be created."
  type        = string
  default     = "ca-central-1"
}

variable "loki_endpoint" {
  description = "The Loki endpoint URL for log shipping."
  type        = string
  default     = "loki.example.com:3100"
}
