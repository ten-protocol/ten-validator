# Azure Validator Node

This repository contains scripts and configurations to set up and manage an Azure Validator Node using Terraform and Ansible.

## Overview

- **Terraform**: Used to provision the necessary Azure infrastructure for the Validator Node.
- **Ansible**: Used to configure the provisioned infrastructure and deploy the Validator Node.

## Requirements

Before you begin, ensure you have the following installed on your local machine:

- [Terraform](https://www.terraform.io/downloads.html) (version >= 0.12)
  - [Installation Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
  - [Installation Guide](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
  - Install necessary Ansible modules:
    ```sh
    ansible-galaxy collection install community.docker community.crypto
    ```
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)
- [Git](https://git-scm.com/downloads)

## Pre-requisites

1. **Authenticate with Azure CLI**:
   ```sh
   az login
   ```

2. **Clone the repository**:
   ```sh
   git clone https://github.com/ten-protocol/ten-validator.git
   cd ten-validator
   ```

3. **Configure Azure Subscription**:
   Ensure your Azure subscription is set correctly:
   ```sh
   az account set --subscription "your-subscription-name"
   ```

## Terraform Setup

### Initialize and Apply Terraform Configuration

1. **Navigate to the Terraform directory**:
   ```sh
   cd terraform
   ```

2. **Copy the example `terraform.tfvars` file and edit it**:
   ```sh
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your preferred settings
   ```

3. **Initialize Terraform**:
   ```sh
   terraform init
   ```

4. **Apply the Terraform configuration**:
   ```sh
   terraform apply
   ```
   Follow the prompts to confirm the infrastructure changes.

5. **Retrieve SSH Key and Login Script**:
   ```sh
   chmod +x get-key.sh
   ./get-key.sh
   ```

## Ansible Deployment

### Deploy the Validator Node

1. **Run the installation script**:
   ```sh
   chmod +x install-ten.sh
   ./install-ten.sh
   ```

You will need to provide the following information:
- Host ID (public key of the validator node wallet)
- Private Key (private key of the validator node wallet)
- Host Public P2P Address (public IP address of the validator node)
- Host ssh username (default is tenuser)*
- Host ssh password or path to ssh key file*
- L1 WS URL (websocket URL of the L1 node)
- Postgres DB Host (leave blank if unsure or want to provision a new one)

\* Note: If you used terraform to provision the VM, you can just press enter and choose the default values.

## Additional Information

- **Clear Terraform State**: If you need to destroy the infrastructure and clear the Terraform state, run:
  ```sh
  chmod +x clear.sh
  ./clear.sh
  ```

- **Environment Variables**: Ensure that all necessary environment variables are set as per the `ansible/files/node.env.example` file.

- **Network Configuration**: The network settings are defined in `ansible/files/network_vars.yml` and should not be changed unless necessary.

## Troubleshooting

- Ensure all dependencies are installed and accessible in your system's PATH.
- Verify that your Azure CLI is authenticated and set to the correct subscription.
- Check that your `terraform.tfvars` and `hosts.ini` files are correctly configured.

For further assistance, refer to the official documentation of each tool or reach out to the project maintainers.
