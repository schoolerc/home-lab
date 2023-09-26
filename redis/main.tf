terraform {
  required_version = ">=1.5"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.23.0"
    }
  }
  backend "kubernetes" {
    secret_suffix = "redis"
    config_path   = "~/.kube/config"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

locals {
  name = "redis"
  port = 6379
  version = "7.2.1"
}

resource "kubernetes_pod_v1" "redis" {
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
      port {
        container_port = local.port
      }
    }
    restart_policy = "OnFailure"
  }
}

resource "kubernetes_service_v1" "redis-cluster-access" {
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
    type = "ClusterIP"
  }
}