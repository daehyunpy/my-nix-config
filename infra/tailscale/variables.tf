variable "enable_muse_ssh" {
  type        = bool
  default     = false
  description = "Switch from the inspected baseline policy to the reviewed Muse SSH policy and assign its tags. Leave false until the baseline plan is empty and the Muse prerequisites are met."
}
