variable "resource_group_location" {
  type        = string
  default     = "uksouth"
  description = "Location of the resource group."
}

variable "resource_group_name" {
  type        = string
  default     = "TEN_VALIDATOR"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "username" {
  type        = string
  default     = "tenuser"
  description = "The username for the local account that will be created on the new VM."
}

# Must be a valid VM size and SGX enabled
variable "vm_size" {
  type        = string
  default     = "Standard_DC2ds_v3"
  description = "The size of the VM."
}

variable "host_http_port" {
  type        = number
  default     = 10000
  description = "The port the web server will listen on."
}

variable "host_websocket_port" {
  type        = number
  default     = 80
  description = "The port the websocket server will listen on."

}

variable "host_p2p_port" {
  type        = number
  default     = 81
  description = "The port the P2P server will listen on."
}
