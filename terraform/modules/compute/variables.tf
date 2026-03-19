variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where instances will be created"
  type        = string
}

variable "machine_type" {
  description = "GCP machine type (e.g., e2-medium, e2-standard-2)"
  type        = string
  default     = "e2-medium"
}

variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 1
}

variable "source_image" {
  description = "Source image for the instances"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2004-lts"
}

variable "disk_size" {
  description = "Disk size in GB"
  type        = number
  default     = 50
}

variable "startup_script" {
  description = "Startup script to run on instances"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Network tags for the instances"
  type        = list(string)
  default     = []
}