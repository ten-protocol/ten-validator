terraform {
  required_version = ">= 0.12"

  required_providers {
    ovh = {
      source  = "ovhhcloud/ovh"
      version = "~> 0.40"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# OVH Provider Configuration
# Set credentials via environment variables:
# OVH_ENDPOINT, OVH_APPLICATION_KEY, OVH_APPLICATION_SECRET, OVH_CONSUMER_KEY
provider "ovh" {
  endpoint           = var.ovh_endpoint
  application_key    = var.ovh_application_key
  application_secret = var.ovh_application_secret
  consumer_key       = var.ovh_consumer_key
}
