# OVH API Credentials
variable "ovh_endpoint" {
  type        = string
  default     = "ovh-eu"
  description = "OVH API endpoint (ovh-eu, ovh-us, etc.)"
}

variable "ovh_application_key" {
  type        = string
  sensitive   = true
  description = "OVH API application key. Get from https://api.ovh.com/createToken/"
}

variable "ovh_application_secret" {
  type        = string
  sensitive   = true
  description = "OVH API application secret"
}

variable "ovh_consumer_key" {
  type        = string
  sensitive   = true
  description = "OVH API consumer key"
}

# OVH Service Configuration
variable "ovh_service_name" {
  type        = string
  description = "OVH bare metal service name. Get from OVH Control Panel (e.g., 'ns12345.ip-1-2-3.eu')"
}

# Server Configuration
variable "username" {
  type        = string
  default     = "tenuser"
  description = "The username for the local account on the server"
}

variable "domain_name" {
  type        = string
  default     = "ovh.net"
  description = "Domain name for reverse DNS"
}

# Ten Validator Ports
variable "host_http_port" {
  type        = number
  default     = 10000
  description = "The port the HTTP server will listen on"
}

variable "host_websocket_port" {
  type        = number
  default     = 80
  description = "The port the WebSocket server will listen on"
}

variable "host_p2p_port" {
  type        = number
  default     = 81
  description = "The port the P2P server will listen on"
}

# Ansible Configuration
variable "ansible_python_interpreter" {
  type        = string
  default     = "/usr/bin/python3"
  description = "Python interpreter path on the remote server"
}

variable "ansible_user" {
  type        = string
  default     = "tenuser"
  description = "Ansible SSH user"
}
