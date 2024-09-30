#!/bin/bash

terraform output -raw private_key_data > ./ssh-key.pem
chmod 600 ./ssh-key.pem

pubip=$(terraform output -raw public_ip_address)

# creates a bash script to login to the instance
echo "ssh -i ssh-key.pem tenuser@${pubip}" > ./ssh-login.sh
chmod +x ./ssh-login.sh
