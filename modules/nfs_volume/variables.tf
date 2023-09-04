variable "access_modes" {
  description = "the access modes of the volume and claim"
  type = list(string)
  default = ["ReadWriteMany"]
}
variable "capacity" {
  description = "the storage capacity of the volume"
  type = string
}

variable "nfs_host" {
  description = "the host of the nfs server"
  default = "nfs.schooler.dev"
  type = string
}

variable "mount_path" {
  description = "the path on the nfs server to mount"
  type = string
}

variable "volume_name" {
  description = "the name to assign to the volume"
  type = string
}

variable "volume_claim_name" {
  description = "the name to assign to the volume claim"
  type = string
}