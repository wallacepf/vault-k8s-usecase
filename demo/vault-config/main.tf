provider "vault" {
  address = "http://${data.kubernetes_service.vault-ui.status[0].load_balancer[0].ingress[0].ip}:8200"
  token   = "root"
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}


data "kubernetes_namespace" "vault" {
  metadata {
    name = "vault-sidecar"
  }
}

data "kubernetes_service" "vault-ui" {
  metadata {
    name      = "vault-ui"
    namespace = data.kubernetes_namespace.vault.metadata.0.name
  }
}

data "kubernetes_service_account" "vault" {
  metadata {
    name      = "vault"
    namespace = data.kubernetes_namespace.vault.metadata.0.name
  }
}

data "kubernetes_secret" "vault" {
  metadata {
    name      = data.kubernetes_service_account.vault.default_secret_name
    namespace = data.kubernetes_namespace.vault.metadata.0.name
  }
}

resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}


resource "vault_kubernetes_auth_backend_config" "kubernetes" {
  backend                = vault_auth_backend.kubernetes.path
  kubernetes_host        = "https://10.96.0.1:443"
  kubernetes_ca_cert     = data.kubernetes_secret.vault.data["ca.crt"]
  token_reviewer_jwt     = data.kubernetes_secret.vault.data.token
  issuer                 = "https://kubernetes.default.svc.cluster.local"
  disable_iss_validation = "true"
}

resource "vault_policy" "vaulidate" {
  name = "vaulidate"

  policy = <<EOT
path "secret/data/vaulidate/mysecret" {
  capabilities = ["read"]
}
EOT
}

resource "vault_generic_secret" "mysecret" {
  path = "secret/vaulidate/mysecret"

  data_json = <<EOT
{
  "username":   "hashicorp",
  "password": "sup3secret"
}
EOT
}

resource "vault_kubernetes_auth_backend_role" "vaulidate_file" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "vaulidate-file"
  bound_service_account_names      = ["vaulidate-file"]
  bound_service_account_namespaces = ["vaulidate-file"]
  token_ttl                        = 3600
  token_policies                   = ["vaulidate"]
}

resource "vault_kubernetes_auth_backend_role" "vaulidate_env" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "vaulidate-env"
  bound_service_account_names      = ["vaulidate-env"]
  bound_service_account_namespaces = ["vaulidate-env"]
  token_ttl                        = 3600
  token_policies                   = ["vaulidate"]
}

resource "vault_kubernetes_auth_backend_role" "vaulidate_native" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "vaulidate-native"
  bound_service_account_names      = ["vaulidate-native"]
  bound_service_account_namespaces = ["vaulidate-native"]
  token_ttl                        = 3600
  token_policies                   = ["vaulidate"]
}

resource "vault_auth_backend" "approle" {
  type = "approle"
}

resource "vault_approle_auth_backend_role" "vaulidate_native" {
  backend        = vault_auth_backend.approle.path
  role_name      = "vaulidate-native"
  token_policies = ["vaulidate"]
}

data "vault_approle_auth_backend_role_id" "role" {
  backend   = "approle"
  role_name = "vaulidate-native"
}

