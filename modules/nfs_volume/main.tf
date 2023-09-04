terraform {
  required_version = ">= 1.5.0"
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = ">= 2.23.0"
    }
  }
}

resource "kubernetes_persistent_volume_v1" "nfs_volume" {
  metadata {
    name = var.volume_name
  }
  spec {
    access_modes = ["ReadWriteMany"]
    capacity     = {
      storage = var.capacity
    }
    persistent_volume_source {
      nfs {
        path   = var.mount_path
        server = var.nfs_host
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "nfs_volume_claim" {
  metadata {
    name = var.volume_claim_name
  }

  spec {
    volume_name = var.volume_name
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = var.capacity
      }
    }
  }
}