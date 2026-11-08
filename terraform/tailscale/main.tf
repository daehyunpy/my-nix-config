provider "tailscale" {
  tailnet = "TByk7otHmv11CNTRL"
}

resource "tailscale_acl" "tailnet" {
  acl = file("${path.module}/policy.hujson")

  lifecycle {
    prevent_destroy = true
  }
}
