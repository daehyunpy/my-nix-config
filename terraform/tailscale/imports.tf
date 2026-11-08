import {
  to = tailscale_acl.tailnet
  id = "acl"
}

import {
  to = tailscale_dns_configuration.tailnet
  id = "dns_configuration"
}

import {
  for_each = local.devices

  to = tailscale_device_key.managed[each.key]
  id = each.value.id
}

import {
  for_each = local.router_routes

  to = tailscale_device_subnet_routes.routers[each.key]
  id = local.devices[each.key].id
}
