# OVH Bare Metal Server with SGX
# This Terraform manages an EXISTING OVH bare metal server
# The server must be ordered manually via OVH Control Panel:
# https://www.ovhcloud.com/manager/
#
# Recommended servers (all have Intel SGX):
# 1. Advance-6 (Intel Xeon Ice Lake) - ~$49-66/month - CHEAPEST with SGX
# 2. Scale-i1 (Intel Xeon) - ~$420/month - 16 vCores, 32GB RAM
#
# Terraform automates:
# - SSH key generation and management
# - Reverse DNS configuration
# - Server connectivity verification
# - Ansible playbook execution for Docker & Ten Validator deployment

# Generate SSH key pair locally
resource "tls_private_key" "ten_validator_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Data source: Get existing OVH server details
data "ovh_dedicated_server" "ten_validator" {
  service_name = var.ovh_service_name
}

# Create reverse DNS entry for the server
resource "ovh_reverse_dns" "ten_validator_rdns" {
  service_name = data.ovh_dedicated_server.ten_validator.service_name
  ip           = data.ovh_dedicated_server.ten_validator.ip
  reverse      = "tenvalidator.${var.domain_name}"
}

# SSH key - store locally for later use
resource "local_file" "ssh_private_key" {
  content              = tls_private_key.ten_validator_key.private_key_pem
  filename             = "${path.module}/ssh-key-ovh.pem"
  file_permission      = "0600"
  directory_permission = "0700"
}

resource "local_file" "ssh_public_key" {
  content              = tls_private_key.ten_validator_key.public_key_openssh
  filename             = "${path.module}/ssh-key-ovh.pub"
  file_permission      = "0644"
  directory_permission = "0700"
}

# Null resource to trigger Ansible provisioning once server is ready
resource "null_resource" "ansible_provisioner" {
  depends_on = [
    data.ovh_dedicated_server.ten_validator,
    local_file.ssh_private_key
  ]

  triggers = {
    server_id = data.ovh_dedicated_server.ten_validator.service_name
    server_ip = data.ovh_dedicated_server.ten_validator.ip
  }

  # Wait for server to be reachable (max 300 seconds)
  provisioner "remote-exec" {
    inline = [
      "echo 'Server is reachable'",
      "uname -a",
      "cat /etc/os-release | grep PRETTY_NAME"
    ]

    connection {
      type        = "ssh"
      user        = var.username
      private_key = tls_private_key.ten_validator_key.private_key_pem
      host        = data.ovh_dedicated_server.ten_validator.ip
      timeout     = "5m"
    }
  }

  # Step 1: Run k3s installation playbook
  provisioner "local-exec" {
    command = <<-EOT
      sleep 30 && \
      ansible-playbook \
        -i '${data.ovh_dedicated_server.ten_validator.ip},' \
        -u ${var.username} \
        --private-key=${local_file.ssh_private_key.filename} \
        --ssh-common-args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null' \
        ../ansible/k3s-install.yaml
    EOT
  }

  # Step 2: Run Helm deployment playbook
  provisioner "local-exec" {
    command = <<-EOT
      sleep 60 && \
      ansible-playbook \
        -i '${data.ovh_dedicated_server.ten_validator.ip},' \
        -u ${var.username} \
        --private-key=${local_file.ssh_private_key.filename} \
        -e "host_http_port=${var.host_http_port}" \
        -e "host_websocket_port=${var.host_websocket_port}" \
        -e "host_p2p_port=${var.host_p2p_port}" \
        --ssh-common-args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null' \
        ../ansible/helm-ten-node-deploy.yaml
    EOT
  }
}

# Output the SSH login command for manual access
resource "local_file" "ssh_login_script" {
  content              = <<-EOT
    #!/bin/bash
    # SSH login to Ten Validator OVH server
    ssh -i ${local_file.ssh_private_key.filename} ${var.username}@${data.ovh_dedicated_server.ten_validator.ip}
  EOT
  filename             = "${path.module}/ssh-login.sh"
  file_permission      = "0755"
  directory_permission = "0700"
}
