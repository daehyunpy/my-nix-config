locals {
  devices = {
    apollo = {
      id                  = "nMzngfCre621CNTRL"
      key_expiry_disabled = false
    }
    thales = {
      id                  = "nhesn3Xjj111CNTRL"
      key_expiry_disabled = true
    }
    poseidon = {
      id                  = "npByKx79tM11CNTRL"
      key_expiry_disabled = true
    }
    muse = {
      id                  = "n3u5ATYqT411CNTRL"
      key_expiry_disabled = false
    }
  }

  router_routes = {
    thales   = ["192.168.2.0/24", "0.0.0.0/0", "::/0"]
    poseidon = ["0.0.0.0/0", "::/0"]
  }
}

resource "tailscale_device_key" "managed" {
  for_each = local.devices

  device_id           = each.value.id
  key_expiry_disabled = each.value.key_expiry_disabled

  lifecycle {
    prevent_destroy = true
  }
}

resource "tailscale_device_subnet_routes" "routers" {
  for_each = local.router_routes

  device_id = local.devices[each.key].id
  routes    = each.value

  lifecycle {
    prevent_destroy = true
  }
}
