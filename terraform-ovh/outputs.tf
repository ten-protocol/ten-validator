output "server_name" {
  value       = data.ovh_dedicated_server.ten_validator.service_name
  description = "OVH Bare Metal Server name"
}

output "server_ip" {
  value       = data.ovh_dedicated_server.ten_validator.ip
  description = "Server public IPv4 address"
}

output "server_ipv6" {
  value       = data.ovh_dedicated_server.ten_validator.ipv6
  description = "Server public IPv6 address block"
}

output "ssh_command" {
  value       = "ssh -i ${local_file.ssh_private_key.filename} ${var.username}@${data.ovh_dedicated_server.ten_validator.ip}"
  description = "SSH command to connect to the server"
}

output "ssh_key_path" {
  value       = local_file.ssh_private_key.filename
  description = "Path to SSH private key"
}

output "ssh_public_key_path" {
  value       = local_file.ssh_public_key.filename
  description = "Path to SSH public key"
}

output "reverse_dns" {
  value       = ovh_reverse_dns.ten_validator_rdns.reverse
  description = "Reverse DNS entry for the server"
}

output "validator_endpoints" {
  value = {
    http_port      = var.host_http_port
    websocket_port = var.host_websocket_port
    p2p_port       = var.host_p2p_port
  }
  description = "Ten Validator network endpoints"
}

output "ansible_inventory_line" {
  value       = "${data.ovh_dedicated_server.ten_validator.ip} ansible_user=${var.username} ansible_ssh_private_key_file=${local_file.ssh_private_key.filename}"
  description = "Ansible inventory line for manual playbook execution"
}

output "next_steps" {
  value = <<-EOT
    # OVH Bare Metal Server deployment completed!

    Server Details:
    - Service Name: ${data.ovh_dedicated_server.ten_validator.service_name}
    - IP Address: ${data.ovh_dedicated_server.ten_validator.ip}
    - SSH Key: ${local_file.ssh_private_key.filename}

    Connect to server:
    ssh -i ${local_file.ssh_private_key.filename} ${var.username}@${data.ovh_dedicated_server.ten_validator.ip}

    Or run the login script:
    bash ${path.module}/ssh-login.sh

    Verify SGX is enabled:
    cpuid | grep SGX

    Check Ten Validator status:
    docker ps
    docker logs ten-validator
  EOT
}
