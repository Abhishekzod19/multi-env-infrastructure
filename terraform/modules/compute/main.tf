# Instance Template
resource "google_compute_instance_template" "template" {
  name_prefix  = "${var.environment}-template-"
  machine_type = var.machine_type
  region       = var.region

  disk {
    source_image = var.source_image
    disk_size_gb = var.disk_size
    disk_type    = "pd-standard"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    subnetwork = var.subnet_id
    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    environment = var.environment
    managed-by  = "terraform"
  }

  metadata_startup_script = var.startup_script
  tags = ["http-server", "ssh-allowed", var.environment]

  lifecycle {
    create_before_destroy = true
  }
}

# Managed Instance Group
resource "google_compute_region_instance_group_manager" "mig" {
  name = "${var.environment}-mig"

  base_instance_name = "${var.environment}-instance"
  region            = var.region
  target_size       = var.instance_count

  version {
    instance_template = google_compute_instance_template.template.id
  }

  named_port {
    name = "http"
    port = 80
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.autohealing.id
    initial_delay_sec = 300
  }
}

# Health Check
resource "google_compute_health_check" "autohealing" {
  name                = "${var.environment}-autohealing"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10

  http_health_check {
    request_path = "/health"
    port         = 80
  }
}