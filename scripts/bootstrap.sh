#!/bin/bash

# Multi-Environment Infrastructure Bootstrap Script
set -e

echo "🚀 Bootstrapping Infrastructure Framework for 3 Projects..."

# Check prerequisites
command -v terraform >/dev/null 2>&1 || { echo "Terraform is required but not installed. Aborting." >&2; exit 1; }
command -v ansible >/dev/null 2>&1 || { echo "Ansible is required but not installed. Aborting." >&2; exit 1; }
command -v gcloud >/dev/null 2>&1 || { echo "Google Cloud SDK is required but not installed. Aborting." >&2; exit 1; }

# Configure GCP
echo "🔑 Configuring GCP..."
gcloud auth application-default login

# Create Terraform state buckets for each environment
echo "📦 Creating Terraform state buckets..."

# Dev bucket
echo "Creating bucket for dev..."
gsutil mb -l us-central1 gs://dev-env-project-490714-tfstate || true
gsutil versioning set on gs://dev-env-project-490714-tfstate

# Staging bucket
echo "Creating bucket for staging..."
gsutil mb -l us-central1 gs://stg-env-project-tfstate || true
gsutil versioning set on gs://stg-env-project-tfstate

# Prod bucket
echo "Creating bucket for prod..."
gsutil mb -l us-central1 gs://prod-env-project-490714-tfstate || true
gsutil versioning set on gs://prod-env-project-490714-tfstate

# Setup Ansible
echo "🛠️  Setting up Ansible..."
pip3 install -r ansible/requirements.txt
chmod +x ansible/inventory/gcp_inventory.py

echo "✅ Bootstrap complete!"
echo ""
echo "Next steps:"
echo "1. Run: cd terraform/environments/dev && terraform init && terraform plan"
echo "2. Deploy each environment using the Jenkins pipeline or manually"