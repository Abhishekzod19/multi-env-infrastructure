terraform {
  backend "gcs" {
    bucket = "prod-env-project-490714-tfstate"
    prefix = "environments/prod"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_compute_zones" "available" {
  region = var.region
}

module "networking" {
  source = "../../modules/networking"
  
  environment = "prod"
  region      = var.region
  subnet_cidrs = [
    "10.20.1.0/24",
    "10.20.2.0/24",
    "10.20.3.0/24",
    "10.20.4.0/24",
    "10.20.5.0/24",
    "10.20.6.0/24"
  ]
  admin_ips = [
    "0.0.0.0/0",
    "10.0.0.0/8",
    "192.168.0.0/16"
  ]
}

module "compute_web" {
  source = "../../modules/compute"
  
  environment    = "prod-web"
  region         = var.region
  subnet_id      = module.networking.subnet_ids[0]
  machine_type   = "e2-standard-4"
  instance_count = 3
  source_image   = "ubuntu-os-cloud/ubuntu-2004-lts"
  disk_size      = 100
  
  startup_script = <<-EOF
    #!/bin/bash
    echo "Environment: production" > /etc/environment
    echo "Role: webserver" >> /etc/environment
    echo "Tier: web" >> /etc/environment
    apt-get update
    apt-get install -y python3 nginx
    systemctl enable nginx
    systemctl start nginx
  EOF
  
  tags = ["prod", "webserver", "http-server", "https-server"]
}

module "compute_app" {
  source = "../../modules/compute"
  
  environment    = "prod-app"
  region         = var.region
  subnet_id      = module.networking.subnet_ids[1]
  machine_type   = "e2-standard-8"
  instance_count = 3
  source_image   = "ubuntu-os-cloud/ubuntu-2004-lts"
  disk_size      = 200
  
  startup_script = <<-EOF
    #!/bin/bash
    echo "Environment: production" > /etc/environment
    echo "Role: appserver" >> /etc/environment
    echo "Tier: application" >> /etc/environment
    apt-get update
    apt-get install -y python3 python3-pip
  EOF
  
  tags = ["prod", "appserver", "internal"]
}

module "compute_db" {
  source = "../../modules/compute"
  
  environment    = "prod-db"
  region         = var.region
  subnet_id      = module.networking.subnet_ids[2]
  machine_type   = "e2-standard-8"
  instance_count = 2
  source_image   = "ubuntu-os-cloud/ubuntu-2004-lts"
  disk_size      = 500
  
  startup_script = <<-EOF
    #!/bin/bash
    echo "Environment: production" > /etc/environment
    echo "Role: database" >> /etc/environment
    apt-get update
    apt-get install -y python3
  EOF
  
  tags = ["prod", "database", "internal"]
}

resource "google_compute_global_address" "prod_lb" {
  name = "prod-lb-ip"
}

resource "google_compute_global_forwarding_rule" "prod_http" {
  name       = "prod-http-rule"
  target     = google_compute_target_http_proxy.prod_http_proxy.id
  port_range = "80"
  ip_address = google_compute_global_address.prod_lb.address
}

resource "google_compute_target_http_proxy" "prod_http_proxy" {
  name    = "prod-http-proxy"
  url_map = google_compute_url_map.prod_url_map.id
}

resource "google_compute_url_map" "prod_url_map" {
  name            = "prod-url-map"
  default_service = google_compute_backend_service.prod_web_backend.id
}

resource "google_compute_backend_service" "prod_web_backend" {
  name      = "prod-web-backend"
  protocol  = "HTTP"
  port_name = "http"
  timeout_sec = 30
  
  backend {
    group = module.compute_web.instance_group
  }
  
  health_checks = [google_compute_health_check.prod_web_health.id]
}

resource "google_compute_health_check" "prod_web_health" {
  name = "prod-web-health"
  
  http_health_check {
    port         = 80
    request_path = "/health"
  }
  
  check_interval_sec = 5
  timeout_sec        = 5
  healthy_threshold  = 2
  unhealthy_threshold = 2
}

resource "google_sql_database_instance" "prod_db" {
  name             = "prod-db-instance"
  database_version = "POSTGRES_13"
  region           = var.region
  
  settings {
    tier              = "db-custom-4-15360"
    availability_type = "REGIONAL"
    
    backup_configuration {
      enabled            = true
      start_time         = "03:00"
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
    }
    
    ip_configuration {
      ipv4_enabled    = false
      private_network = module.networking.vpc_id
      
      authorized_networks {
        name  = "office"
        value = "0.0.0.0/0"
      }
    }
    
    disk_size = 500
    disk_type = "PD_SSD"
  }
  
  deletion_protection = true
}

output "prod_web_ips" {
  value = module.compute_web.instance_ips
  description = "IP addresses of production web servers"
}

output "prod_app_ips" {
  value = module.compute_app.instance_ips
  description = "IP addresses of production app servers"
}

output "prod_lb_ip" {
  value = google_compute_global_address.prod_lb.address
  description = "Production load balancer IP address"
}

output "prod_db_connection" {
  value = google_sql_database_instance.prod_db.private_ip_address
  description = "Production database private IP"
}

output "vpc_network_name" {
  value = module.networking.vpc_name
  description = "VPC network name"
}