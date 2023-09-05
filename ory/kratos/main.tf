terraform {
  required_version = ">=1.5"
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.23.0"
    }
  }
    backend "kubernetes" {
    secret_suffix = "ory-kratos"
    config_path = "~/.kube/config"
  }
}

locals {
  name = "kratos"
  version = "v0.8"
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

module "nfs_volume" {
  source = "../../modules/nfs_volume"

  capacity          = "10Gi"
  mount_path        = "/mnt/external-storage/ory/kratos"
  volume_claim_name = local.name
  volume_name       = local.name
}

data "kubernetes_service_v1" "mysql-cluster" {
  metadata {
    name = "mysql-cluster"
  }
}

resource "kubernetes_pod_v1" "kratos" {
  metadata {
    name = local.name
  }

  spec {
    container {
      name = local.name
      image = "oryd/kratos:${local.version}"
    }
  }
}
