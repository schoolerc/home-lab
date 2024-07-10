terraform {
  required_version = ">= 1.9.1"

  backend "kubernetes" {
    secret_suffix = "storage"
    config_path   = "~/.kube/config"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_storage_class_v1" "ext_ephemeral" {
  metadata {
    name = "ext-ephemeral-storage"
  }
  storage_provisioner = "rancher.io/local-path"
  parameters = {
    nodePath    = "/mnt/storage"
    pathPattern = "{{ .PVC.Namespace }}/{{ .PVC.Name }}"
  }
  volume_binding_mode = "WaitForFirstConsumer"
  reclaim_policy      = "Delete"
}

resource "kubernetes_storage_class_v1" "ext_persistent" {
  metadata {
    name = "ext-persistent-storage"
  }
  storage_provisioner = "rancher.io/local-path"
  parameters = {
    nodePath    = "/mnt/storage"
    pathPattern = "{{ .PVC.Namespace }}/{{ .PVC.Name }}"
  }
  volume_binding_mode = "WaitForFirstConsumer"
  reclaim_policy      = "Retain"
}
