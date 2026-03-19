variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "subnet_cidrs" {
  description = "List of subnet CIDR ranges"
  type        = list(string)
}

variable "admin_ips" {
  description = "IP ranges allowed for SSH access"
  type        = list(string)
}