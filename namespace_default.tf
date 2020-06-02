module "namespace_default" {
  source = "git::https://github.com/canada-ca-terraform-modules/terraform-kubernetes-namespace.git?ref=v1.0.0"

  name = "default"
  namespace_admins = {
    users = []
    groups = [
      "${var.kubernetes_rbac_group}"
    ]
  }

  # ServiceAccount
  helm_service_account = "tiller"

  # CICD
  ci_name = "argo"

  # Image Pull Secret
  # enable_kubernetes_secret = "${var.enable_kubernetes_secret}"
  # kubernetes_secret = "${var.kubernetes_secret}"
  # docker_repo = "${var.docker_repo}"
  # docker_username = "${var.docker_username}"
  # docker_password = "${var.docker_password}"
  # docker_email = "${var.docker_email}"
  # docker_auth = "${var.docker_auth}"

  dependencies = []
}

# Default

resource "null_resource" "default" {

  provisioner "local-exec" {
    command = "kubectl label ns default control-plane=default --overwrite"
  }
}
