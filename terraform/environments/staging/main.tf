terraform {
  backend "gcs" {
    bucket = "stg-env-project-tfstate"
    prefix = "environments/staging"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "networking" {
  source = "../../modules/networking"
  
  environment = "staging"
  region      = var.region
  subnet_cidrs = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
  admin_ips   = ["YOUR_OFFICE_IP/32", "VPN_IP_RANGE"]
}

module "compute" {
  source = "../../modules/compute"
  
  environment    = "staging"
  region         = var.region
  subnet_id      = module.networking.subnet_ids[0]
  machine_type   = "e2-standard-2"
  instance_count = 3
  source_image   = "ubuntu-os-cloud/ubuntu-2004-lts"
  disk_size      = 100
}