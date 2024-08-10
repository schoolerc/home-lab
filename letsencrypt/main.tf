terraform {
  required_version = ">= 1.9.1"

  backend "kubernetes" {
    secret_suffix = "letsencrypt"
    config_path   = "~/.kube/config"
  }

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "kubectl" {
  config_path = "~/.kube/config"
}

resource "kubectl_manifest" "cluster_issuer" {
  yaml_body = file("./cluster_issuer.yaml")
}