terraform {
  backend "s3" {
    key = "tailscale/terraform.tfstate"
  }
}
