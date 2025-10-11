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

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "ca-central-1"
}

variable "tailscale_auth_key" {
  description = "Tailscale auth key for secure access"
  type        = string
}

variable "log_groups" {
  description = "List of CloudWatch log group names to subscribe to"
  type        = list(string)
}
