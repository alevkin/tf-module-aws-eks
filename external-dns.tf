resource "kubernetes_service_account" "external_dns" {
  depends_on = ["null_resource.check_api"]
  metadata {
    name      = "external-dns"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role" "external_dns" {
  depends_on = ["null_resource.check_api"]
  metadata {
    name = "external-dns"
  }

  rule {
    verbs      = ["get", "watch", "list"]
    api_groups = [""]
    resources  = ["services"]
  }

  rule {
    verbs      = ["get", "watch", "list"]
    api_groups = [""]
    resources  = ["pods"]
  }

  rule {
    verbs      = ["get", "watch", "list"]
    api_groups = ["extensions"]
    resources  = ["ingresses"]
  }

  rule {
    verbs      = ["get", "watch", "list"]
    api_groups = [""]
    resources  = ["nodes"]
  }
}

resource "kubernetes_cluster_role_binding" "external_dns_viewer" {
  depends_on = ["null_resource.check_api"]
  metadata {
    name = "external-dns-viewer"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "external-dns"
    namespace = "kube-system"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "external-dns"
  }
}

resource "kubernetes_deployment" "external_dns" {
  depends_on = ["null_resource.check_api"]
  metadata {
    name      = "external-dns"
    namespace = "kube-system"
  }

  spec {

    selector {
      match_labels = {
        name      = "external-dns"
        namespace = "kube-system"
      }
    }

    template {
      metadata {
        labels = {
          name      = "external-dns"
          namespace = "kube-system"
        }
      }

      spec {
        automount_service_account_token = true 
        container {
          name  = "external-dns"
          image = "registry.opensource.zalan.do/teapot/external-dns:v0.5.8"
          args  = ["--source=ingress", "--domain-filter=${var.root_domain[0]}", "--provider=aws", "--policy=sync", "--aws-zone-type=public", "--registry=txt", "--txt-owner-id=${var.project}-${var.environment}", "--txt-prefix=${var.project}-${var.environment}."]
        }

        service_account_name = "external-dns"
      }
    }

    strategy {
      type = "Recreate"
    }
  }
}

