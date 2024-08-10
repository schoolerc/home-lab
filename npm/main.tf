terraform {
  required_version = ">= 1.9.1"

  backend "kubernetes" {
    secret_suffix = "npm"
    config_path   = "~/.kube/config"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "kubernetes_persistent_volume_claim_v1" "verdaccio" {
  metadata {
    name = "verdaccio-pvc"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    storage_class_name = "local-path"
    resources {
      requests = {
        storage = "16Gi"
      }
    }
  }
  # local-path storage class uses WaitForFirstConsumer
  wait_until_bound = false
}

resource "helm_release" "verdaccio" {
  chart      = "verdaccio"
  name       = "npm"
  repository = "https://charts.verdaccio.org/"
  version    = "4.17.0"

  values = [file("values.yaml")]

  set {
    name  = "persistence.existingClaim"
    value = kubernetes_persistent_volume_claim_v1.verdaccio.metadata[0].name
  }
}

