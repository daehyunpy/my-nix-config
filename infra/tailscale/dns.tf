resource "tailscale_dns_preferences" "magic_dns" {
  magic_dns = true
}

resource "tailscale_dns_nameservers" "global" {
  nameservers = [
    "1.1.1.1",
    "1.0.0.1",
    "2606:4700:4700::1111",
    "2606:4700:4700::1001",
  ]
}

import {
  to = tailscale_dns_preferences.magic_dns
  id = "dns_preferences"
}

import {
  to = tailscale_dns_nameservers.global
  id = "dns_nameservers"
}
