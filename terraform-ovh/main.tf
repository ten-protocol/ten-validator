# OVH Bare Metal Server with SGX - Scale-i1
# Minimum cost SGX-enabled instance equivalent to Azure DC2ds_v3
# Specs: 16 vCores, 32GB RAM, Intel Xeon Scalable with SGX
# Cost: ~$420/month vs Azure DC2ds_v3 ~$200-300/month but OVH provides true SGX

# Get SSH public key
data "ovh_dedicated_server_booted_disk" "server_os" {
  service_name = ovh_dedicated_server.ten_validator.service_name
  depends_on   = [ovh_dedicated_server.ten_validator]
}

# Generate SSH key pair
resource "random_id" "ssh_key" {
  byte_length = 8
}

resource "tls_private_key" "ten_validator_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create OVH Bare Metal Server (Scale-i1 with SGX)
resource "ovh_dedicated_server" "ten_validator" {
  service_name = var.ovh_service_name

  # Boot configuration - install Ubuntu 22.04 LTS
  boot_mode = "uefi"

  # Installation will be done via OVH Control Panel or API
  # For automated setup, use ovh_installation_template

  lifecycle {
    ignore_changes = [
      boot_id,
    ]
  }
}

# Create reverse DNS entry for the server
resource "ovh_reverse_dns" "ten_validator_rdns" {
  service_name = ovh_dedicated_server.ten_validator.service_name
  ip           = ovh_dedicated_server.ten_validator.ip
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
  depends_on = [ovh_dedicated_server.ten_validator]

  triggers = {
    server_id = ovh_dedicated_server.ten_validator.service_name
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
      host        = ovh_dedicated_server.ten_validator.ip
      timeout     = "5m"
    }
  }

  # Run Ansible playbook for Docker and Ten Validator setup
  provisioner "local-exec" {
    command = <<-EOT
      sleep 30 && \
      ansible-playbook \
        -i '${ovh_dedicated_server.ten_validator.ip},' \
        -u ${var.username} \
        --private-key=${local_file.ssh_private_key.filename} \
        -e "host_http_port=${var.host_http_port}" \
        -e "host_websocket_port=${var.host_websocket_port}" \
        -e "host_p2p_port=${var.host_p2p_port}" \
        --ssh-common-args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null' \
        ../ansible/setup-validator-playbook.yaml
    EOT
  }
}

# Output the SSH login command for manual access
resource "local_file" "ssh_login_script" {
  content              = <<-EOT
    #!/bin/bash
    # SSH login to Ten Validator OVH server
    ssh -i ${local_file.ssh_private_key.filename} ${var.username}@${ovh_dedicated_server.ten_validator.ip}
  EOT
  filename             = "${path.module}/ssh-login.sh"
  file_permission      = "0755"
  directory_permission = "0700"
}
