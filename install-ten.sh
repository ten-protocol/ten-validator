#!/bin/bash

# Function to prompt for input with validation
prompt_for_input() {
  local prompt_message=$1
  local input_variable_name=$2
  local validation_regex=$3

  while true; do
    echo "$prompt_message"
    read input_value
    if [[ $input_value =~ $validation_regex ]]; then
      eval $input_variable_name="'$input_value'"
      break
    else
      echo "Invalid input. Please try again."
    fi
  done
}

# Prompt for HOST_ID
prompt_for_input "Please enter your HOST_ID (this is the public key of your validator account, e.g., 0x1234...):" HOST_ID '^0x[0-9a-fA-F]+$'

# Prompt for PRIVATE_KEY
prompt_for_input "Please enter your PRIVATE_KEY associated with the HOST_ID (without the 0x prefix):" PRIVATE_KEY '^[0-9a-fA-F]+$'

# Prompt for HOST_PUBLIC_P2P_ADDR_ROOT
prompt_for_input "Please enter the DNS or external IP of your validator node (e.g., validator.example.com or 8.2.27.123):" HOST_PUBLIC_P2P_ADDR_ROOT '^[a-zA-Z0-9.-]+$'

HOST_PUBLIC_P2P_ADDR="${HOST_PUBLIC_P2P_ADDR_ROOT}:10000"
HOST_P2P_PORT="10000"
LOG_LEVEL="3"

# Prompt for L1_WS_URL
prompt_for_input "Please enter the L1_WS_URL (a Sepolia client websocket URL, e.g., ws:// or wss://...):" L1_WS_URL '^wss?://.+$'

# Prompt for DEPLOY_POSTGRES
echo "Would you like to use an existing external Postgres instance? (Default is No - one will be deployed) [N/y]:"
read DEPLOY_POSTGRES

if [[ "$DEPLOY_POSTGRES" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  INCLUDE_POSTGRES_DB_HOST="true"
  # Prompt for POSTGRES_DB_HOST
  prompt_for_input "Please enter the POSTGRES_DB_HOST (Postgres login URI):" POSTGRES_DB_HOST '^.+$'
else
  INCLUDE_POSTGRES_DB_HOST="false"
fi

# Generate a random password for Ansible Vault
VAULT_PASSWORD=$(openssl rand -base64 32)

# Write the password to a .vaultpass file
echo "$VAULT_PASSWORD" > .vaultpass

# Create the YAML file
cat > ./ansible/files/node_secrets.yml <<EOL
HOST_ID: "${HOST_ID}"
PRIVATE_KEY: "${PRIVATE_KEY}"
HOST_PUBLIC_P2P_ADDR: "${HOST_PUBLIC_P2P_ADDR}"
HOST_P2P_PORT: "${HOST_P2P_PORT}"
L1_WS_URL: "${L1_WS_URL}"
LOG_LEVEL: ${LOG_LEVEL}
EOL

if [ "$INCLUDE_POSTGRES_DB_HOST" = "true" ]; then
  echo "POSTGRES_DB_HOST: \"${POSTGRES_DB_HOST}\"" >> ./ansible/files/node_secrets.yml
elif [ "$INCLUDE_POSTGRES_DB_HOST" = "false" ]; then
  echo "POSTGRES_DB_HOST: \"\"" >> ./ansible/files/node_secrets.yml
fi

# Encrypt the file with ansible-vault using the .vaultpass file
ansible-vault encrypt ./ansible/files/node_secrets.yml --vault-password-file .vaultpass

# Ask user to confirm before proceeding
echo "The Ansible playbook will now be run. Please confirm by pressing Enter... (Ctrl+C to cancel)"
read

# Run the Ansible playbook
ansible-playbook ./ansible/setup-validator-playbook.yaml