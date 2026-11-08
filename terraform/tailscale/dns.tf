resource "tailscale_dns_configuration" "tailnet" {
  magic_dns          = true
  override_local_dns = false
  search_paths       = []

  nameservers {
    address            = "1.1.1.1"
    use_with_exit_node = false
  }

  nameservers {
    address            = "8.8.8.8"
    use_with_exit_node = false
  }

  lifecycle {
    prevent_destroy = true
  }
}
