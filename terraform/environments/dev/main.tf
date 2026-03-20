terraform {
  backend "gcs" {
    bucket = "dev-env-project-490714-tfstate"
    prefix = "environments/dev"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "networking" {
  source = "../../modules/networking"
  
  environment = "dev"
  region      = var.region
  subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  admin_ips   = ["176.61.39.68/32"]
}

module "compute" {
  source = "../../modules/compute"
  
 
  environment    = "dev"
  region         = var.region
  subnet_id      = module.networking.subnet_ids[0]
  machine_type   = "e2-medium"
  instance_count = 2
  source_image   = "debian-cloud/debian-12"
  disk_size      = 50
  startup_script = ""
  tags           = ["dev", "webserver"]
}

# Enable Monitoring API
resource "google_project_service" "monitoring" {
  service = "monitoring.googleapis.com"
  disable_on_destroy = false
}

# Email notification channel
resource "google_monitoring_notification_channel" "dev_email" {
  display_name = "Dev Environment Email Alerts"
  type         = "email"
  labels = {
    email_address = "abhishekzod@gmail.com"  # Change to your email
  }
}

# CPU Alert
resource "google_monitoring_alert_policy" "cpu_alert" {
  display_name = "Dev - High CPU Usage"
  combiner     = "OR"
  
  conditions {
    display_name = "CPU > 80%"
    condition_threshold {
      filter     = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" AND resource.labels.project_id=\"dev-env-project-490714\""
      duration   = "300s"
      comparison = "COMPARISON_GT"
      threshold_value = 0.8
      aggregations {
        alignment_period     = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = [google_monitoring_notification_channel.dev_email.name]
}