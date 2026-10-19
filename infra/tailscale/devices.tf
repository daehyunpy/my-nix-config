locals {
  devices = {
    apollo = {
      node_id             = "nMzngfCre621CNTRL"
      key_expiry_disabled = false
      # No approved subnet or exit-node routes were exposed.
      routes = []
    }
    thales = {
      node_id             = "nrGyKDY9Dv11CNTRL"
      key_expiry_disabled = true
      # 192.168.68.0/24 is the approved subnet. 0.0.0.0/0 and ::/0 are the
      # provider's exit-node routes; exit-node approval was allowed.
      routes = ["192.168.68.0/24", "0.0.0.0/0", "::/0"]
    }
    poseidon = {
      node_id             = "npByKx79tM11CNTRL"
      key_expiry_disabled = true
      # Exit-node approval was allowed. No subnet route was exposed.
      routes = ["0.0.0.0/0", "::/0"]
    }
  }
}

resource "tailscale_device_key" "managed" {
  for_each = local.devices

  device_id           = each.value.node_id
  key_expiry_disabled = each.value.key_expiry_disabled

  lifecycle {
    prevent_destroy = true
  }
}

resource "tailscale_device_subnet_routes" "managed" {
  for_each = local.devices

  device_id = each.value.node_id
  routes    = each.value.routes

  lifecycle {
    prevent_destroy = true
  }
}

import {
  for_each = local.devices
  to       = tailscale_device_key.managed[each.key]
  id       = each.value.node_id
}

import {
  for_each = local.devices
  to       = tailscale_device_subnet_routes.managed[each.key]
  id       = each.value.node_id
}

resource "tailscale_device_tags" "muse" {
  count = var.enable_muse_ssh ? 1 : 0

  device_id = "n3u5ATYqT411CNTRL"
  tags      = ["tag:muse"]

  lifecycle {
    prevent_destroy = true
  }
}

resource "tailscale_device_tags" "muse_ssh_target" {
  for_each = var.enable_muse_ssh ? {
    thales   = local.devices.thales.node_id
    poseidon = local.devices.poseidon.node_id
  } : {}

  device_id = each.value
  tags      = ["tag:muse-ssh-target"]

  lifecycle {
    prevent_destroy = true
  }
}

resource "tailscale_device_key" "muse" {
  count = var.enable_muse_ssh ? 1 : 0

  device_id           = "n3u5ATYqT411CNTRL"
  key_expiry_disabled = false

  lifecycle {
    prevent_destroy = true
  }
}
