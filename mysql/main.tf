terraform {
  required_version = ">=1.5"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.23.0"
    }
  }
  backend "kubernetes" {
    secret_suffix = "mysql"
    config_path   = "~/.kube/config"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

locals {
  name = "mysql"
  port = 3306
  storage = "100Gi"
  version = "8.1"
}

module "nfs_volume" {
  source = "../modules/nfs_volume"
  volume_name = local.name
  volume_claim_name = local.name
  capacity = local.storage
  mount_path = "/mnt/external-storage/kubernetes/mysql"
}

resource "kubernetes_pod_v1" "mysql" {
  metadata {
    name = local.name
    labels = {
      app = local.name
    }
  }
  spec {
    container {
      name = local.name
      image = "${local.name}:${local.version}"
      env {
        name = "MYSQL_RANDOM_ROOT_PASSWORD"
        value = true
      }
      env {
        name = "MYSQL_ONETIME_PASSWORD"
        value = true
      }
      port {
        container_port = local.port
      }
      volume_mount {
        mount_path = "/var/lib/mysql"
        name = local.name
      }
    }
    volume {
      name = local.name
      persistent_volume_claim {
        claim_name = local.name
      }
    }
    restart_policy = "OnFailure"
  }
}

resource "kubernetes_service_v1" "mysql-cluster-access" {
    metadata {
    name = "${local.name}-cluster"
  }
  spec {
    selector = {
      app = local.name
    }
    port {
      port = local.port
      target_port = local.port
    }
  }
}

resource "kubernetes_service_v1" "mysql-external-access" {
  metadata {
    name = "${local.name}-external"
  }
  spec {
    selector = {
      app = local.name
    }
    port {
      port = local.port
      target_port = local.port
    }
    type = "NodePort"
  }
}