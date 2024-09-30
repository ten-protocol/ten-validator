# Azure Validator Node

Create a new Azure Validator Node with the following steps:

## Overview

This repository contains scripts and configurations to set up and manage an Azure Validator Node using Terraform and Ansible.

### Terraform

Terraform scripts are located in the [./terraform](./terraform) directory. These scripts are used to provision the necessary Azure infrastructure for the Validator Node.

### Ansible

Ansible playbooks are located in the [./ansible](./ansible) directory. These playbooks are used to configure the provisioned infrastructure and deploy the Validator Node.

## Requirements

Before you begin, ensure you have the following installed:

- [Terraform](https://www.terraform.io/downloads.html)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)

## Pre-requisites
Authenticate with Azure CLI
```sh
az login
```

## Installation

1. **Clone the repository:**

    ```sh
    git clone https://github.com/ten-protocol/ten-validator.git
    cd ten-validator
    ```

2. **Install Terraform:**

    Follow the instructions on the [Terraform website](https://www.terraform.io/downloads.html) to install Terraform.

3. **Install Ansible:**

    Follow the instructions on the [Ansible website](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) to install Ansible.

4. **Install Azure CLI:**

    Follow the instructions on the [Azure CLI website](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) to install the Azure CLI.

## Usage

### Terraform

1. **Navigate to the Terraform directory:**

    ```sh
    cd AzureTerra/terraform
    ```

2. **Initialize Terraform:**

    ```sh
    terraform init
    ```

3. **Apply the Terraform configuration:**

    ```sh
    terraform apply
    ```

    Follow the prompts to confirm the infrastructure changes.

### Login to Validator Node
#### get-key.sh

The `get-key.sh` script is used to retrieve necessary keys for the Validator Node and generate a simple ssh-login.sh script to login to the Validator Node.

1. **Run the script:**

    ```sh
    chmod +x get-key.sh
    ./get-key.sh
    ```

2. **Run the generated script:**

    ```sh
    chmod +x ssh-login.sh
    ./ssh-login.sh
    ```

    This will log you into the Validator Node.

### Ansible

1. **Navigate to the Ansible directory:**

    ```sh
    cd AzureTerra/ansible
    ```

2. **Run the Ansible playbook:**

    ```sh
    ansible-playbook -i inventory main.yml
    ```

    Ensure that the `inventory` file is correctly configured with the details of your provisioned infrastructure.
