terraform {
  required_version = ">= 1.5.0"
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = ">= 2.23.0"
    }
  }

  backend "kubernetes" {
    config_path = "~/.kube/config"
    secret_suffix = "ory-kratos-migration"
  }
}

locals {
  credentials_name = "kratos-mysql"
  name = "kratos-migration"
  version = "v0.8"
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

data "kubernetes_secret_v1" "kratos_mysql_credentials" {
  metadata {
    name = local.credentials_name
  }
}

module "nfs_volume" {
  source = "../../../modules/nfs_volume"

  capacity          = "10Gi"
  mount_path        = "/mnt/external-storage/kubernetes/ory/kratos"
  volume_claim_name = local.name
  volume_name       = local.name
}

resource "kubernetes_job_v1" "kratos_migration" {
  metadata {
    name = local.name
  }
  spec {
    template {
      metadata {
        name = local.name
      }
      spec {
        container {
          name = local.name
          image = "oryd/kratos:${local.version}"
          command = ["kratos", "migrate", "sql", "-e", "--config", "/home/ory/kratos.yml"]
          env {
            name = "DSN"
            value = "mysql://${data.kubernetes_secret_v1.kratos_mysql_credentials.data.username}:${data.kubernetes_secret_v1.kratos_mysql_credentials.data.password}@tcp(mysql.kube.schooler.dev:3306)/kratos?parseTime=true"
          }
          volume_mount {
            mount_path = "/home/ory/"
            name       = local.name
          }
        }
        restart_policy = "Never"
        volume {
          name = local.name
          persistent_volume_claim {
            claim_name = local.name
          }
        }
      }
    }
  }
}
