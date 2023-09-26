terraform {
  required_version = ">= 1.5.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.23.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.11.0"
    }
  }

  backend "kubernetes" {
    secret_suffix = "mailu"
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

module "nfs_volume" {
  source = "../modules/nfs_volume"
  capacity = "100Gi"
  mount_path = "/mnt/kubernetes/service/mailu"
  volume_claim_name = "mailu"
  volume_name = "mailu"
}

resource "helm_release" "mailu" {
  name = "mailu"

  repository = "https://mailu.github.io/helm-charts/"
  chart      = "mailu"
  values = [
  "${file("values.yml")}"]
}