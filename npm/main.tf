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

locals {
  plugins_path = "/opt/verdaccio/plugins"
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

resource "kubernetes_persistent_volume_claim_v1" "verdaccio_plugins" {
  metadata {
    name = "verdaccio-plugins-pvc"
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    storage_class_name = "local-path"
    resources {
      requests = {
        storage = "8Gi"
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

  set {
    name  = "existingConfigMap"
    value = kubernetes_config_map_v1.verdaccio_config.metadata[0].name
  }

  set {
    name = "persistence.mounts"
    value = yamlencode([
      {
        mountPath = local.plugins_path
        name      = "plugins"
      }
    ])
  }

  set {
    name = "persistence.volumes"
    value = yamlencode([
      {
        name = "plugins"
        persistentVolumeClaim = {
          claimName = kubernetes_persistent_volume_claim_v1.verdaccio_plugins.metadata[0].name
        }
      }
    ])
  }
}

data "kubernetes_secret_v1" "verdaccio_github_oauth" {
  metadata { name = "verdaccio-secrets" }
  binary_data = {
    github_client_id     = ""
    github_client_secret = ""
    github_token         = ""
  }
}

resource "kubernetes_config_map_v1" "verdaccio_config" {
  metadata {
    name = "verdaccio-config"
  }
  data = {
    "config.yaml" = yamlencode({
      auth = {
        "github-oauth-ui" = {
          "client-id" = base64decode(data.kubernetes_secret_v1.verdaccio_github_oauth.binary_data.github_client_id)
          "client-secret" = base64decode(data.kubernetes_secret_v1.verdaccio_github_oauth.binary_data.github_client_secret)
          "token" = base64decode(data.kubernetes_secret_v1.verdaccio_github_oauth.binary_data.github_token)
        }
      }
      middlewares = {
        "github-oauth-ui" = {
          enabled = true
        }
      }
      packages = {
        "**" = {
          access = "github/user/schoolerc"
          publish = "github/user/schoolerc"
        }
      }
      plugins = "${local.plugins_path}/node_modules"
      security = {
        api = {
          jwt = {
            sign = {
              expiresIn = "7d"
            }
          }
        }
      }
      storage = "./storage"
      uplinks = {
        npm = {
          url = "https://registry.npmjs.org/"
        }
      }
    })
  }
}