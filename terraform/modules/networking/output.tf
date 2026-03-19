output "vpc_id" {
  description = "VPC network ID"
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "VPC network name"
  value       = google_compute_network.vpc.name
}

output "subnet_ids" {
  description = "List of subnet IDs"
  value       = google_compute_subnetwork.subnets[*].id
}

output "subnet_names" {
  description = "List of subnet names"
  value       = google_compute_subnetwork.subnets[*].name
}

output "subnet_regions" {
  description = "List of subnet regions"
  value       = google_compute_subnetwork.subnets[*].region
}