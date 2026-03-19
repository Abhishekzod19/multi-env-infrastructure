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
  admin_ips   = ["YOUR_OFFICE_IP/32"]
}

module "compute" {
  source = "../../modules/compute"
  
  # Use the EXACT argument names from your module
  environment    = "dev"
  region         = var.region
  subnet_id      = module.networking.subnet_ids[0]
  machine_type   = "e2-medium"
  instance_count = 2
  source_image   = "ubuntu-os-cloud/ubuntu-2004-lts"
  disk_size      = 50
  startup_script = ""
  tags           = ["dev", "webserver"]
}