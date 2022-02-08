provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}


resource "helm_release" "vault" {
  name      = "vault"
  namespace = kubernetes_namespace.vault_sidecar.metadata.0.name

  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"

  values = [
    "${file("vault-sidecar.yml")}"
  ]
}

resource "kubernetes_namespace" "vault_sidecar" {
  metadata {
    name = "vault-sidecar"
  }
}

// Vault Configuration

