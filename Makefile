.PHONY: init plan apply destroy ansible

ENV ?= dev

# Project IDs mapping
DEV_PROJECT = dev-env-project-490714
STAGING_PROJECT = stg-env-project
PROD_PROJECT = prod-env-project-490714

# Get project ID based on environment
PROJECT_ID = $(shell if [ "$(ENV)" = "dev" ]; then echo "$(DEV_PROJECT)"; \
                     elif [ "$(ENV)" = "staging" ]; then echo "$(STAGING_PROJECT)"; \
                     elif [ "$(ENV)" = "prod" ]; then echo "$(PROD_PROJECT)"; fi)

init:
	cd terraform/environments/$(ENV) && terraform init \
		-backend-config=bucket=$(PROJECT_ID)-tfstate

plan: init
	cd terraform/environments/$(ENV) && terraform plan

apply: init
	cd terraform/environments/$(ENV) && terraform apply -auto-approve

destroy: init
	cd terraform/environments/$(ENV) && terraform destroy -auto-approve

ansible:
	ansible-playbook -i ansible/inventory/gcp_inventory.py \
		ansible/playbooks/$(ENV).yml \
		--extra-vars "environment=$(ENV)"

all: apply ansible