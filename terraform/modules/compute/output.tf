output "instance_ips" {
  description = "IP addresses of created instances"
  value       = google_compute_instance_template.template.*.network_interface.0.access_config.0.nat_ip
}

output "instance_group" {
  description = "Instance group manager"
  value       = google_compute_region_instance_group_manager.mig.instance_group
}

output "instance_names" {
  description = "Names of created instances"
  value       = google_compute_instance_template.template.*.name
}