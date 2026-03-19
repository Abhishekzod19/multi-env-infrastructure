// vars/terraformDeploy.groovy
def call(Map config) {
    pipeline {
        agent any
        
        parameters {
            choice(
                name: 'ENVIRONMENT',
                choices: config.environments ?: ['dev', 'staging', 'prod'],
                description: 'Target environment'
            )
        }
        
        stages {
            stage('Infrastructure') {
                steps {
                    script {
                        terraformDeployStage(
                            environment: params.ENVIRONMENT,
                            action: 'apply'
                        )
                    }
                }
            }
            
            stage('Configuration') {
                steps {
                    script {
                        ansibleConfigureStage(
                            environment: params.ENVIRONMENT
                        )
                    }
                }
            }
        }
    }
}

// vars/terraformDeployStage.groovy
def call(Map config) {
    dir("terraform/environments/${config.environment}") {
        sh """
            terraform init
            terraform plan -out=tfplan
            terraform apply tfplan
        """
    }
}

// vars/ansibleConfigureStage.groovy
def call(Map config) {
    dir('ansible') {
        sh """
            ansible-playbook -i inventory/gcp_inventory.py \
                playbooks/${config.environment}.yml \
                --extra-vars "environment=${config.environment}"
        """
    }
}