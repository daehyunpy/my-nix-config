resource "tailscale_acl" "policy" {
  acl                        = file(var.enable_muse_ssh ? "${path.module}/policy.muse.hujson" : "${path.module}/policy.baseline.hujson")
  overwrite_existing_content = false
  reset_acl_on_destroy       = false
}

import {
  to = tailscale_acl.policy
  id = "acl"
}
