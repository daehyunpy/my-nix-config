terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  required_providers {
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.29.2"
    }
  }
}
