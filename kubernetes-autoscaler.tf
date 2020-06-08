resource "kubernetes_config_map" "cluster_autoscaler_priority_expander" {
  depends_on = [kubernetes_priority_class.high_priority_deployments]
  metadata {
    name      = "cluster-autoscaler-priority-expander"
    namespace = "kube-system"
  }

  data = {
    priorities = "100:\n  - ^${var.project}-${var.environment}-spot.*\n50:\n  - ^${var.project}-${var.environment}-on-demand.*"
  }
}

resource "kubernetes_service_account" "cluster_autoscaler" {
  depends_on = [
    kubernetes_priority_class.high_priority_deployments,
    kubernetes_config_map.cluster_autoscaler_priority_expander,
  ]
  metadata {
    name      = "cluster-autoscaler"
    namespace = "kube-system"

    labels = {
      k8s-addon = "cluster-autoscaler.addons.k8s.io"
      k8s-app   = "cluster-autoscaler"
    }
  }
}

resource "kubernetes_cluster_role" "cluster_autoscaler" {
  depends_on = [
    kubernetes_priority_class.high_priority_deployments,
    kubernetes_config_map.cluster_autoscaler_priority_expander,
  ]
  metadata {
    name = "cluster-autoscaler"

    labels = {
      k8s-addon = "cluster-autoscaler.addons.k8s.io"
      k8s-app   = "cluster-autoscaler"
    }
  }

  rule {
    verbs      = ["create", "patch"]
    api_groups = [""]
    resources  = ["events", "endpoints"]
  }

  rule {
    verbs      = ["create"]
    api_groups = [""]
    resources  = ["pods/eviction"]
  }

  rule {
    verbs      = ["update"]
    api_groups = [""]
    resources  = ["pods/status"]
  }

  rule {
    verbs          = ["get", "update"]
    api_groups     = [""]
    resources      = ["endpoints"]
    resource_names = ["cluster-autoscaler"]
  }

  rule {
    verbs      = ["watch", "list", "get", "update"]
    api_groups = [""]
    resources  = ["nodes"]
  }

  rule {
    verbs      = ["watch", "list", "get"]
    api_groups = [""]
    resources  = ["pods", "services", "replicationcontrollers", "persistentvolumeclaims", "persistentvolumes"]
  }

  rule {
    verbs      = ["watch", "list", "get"]
    api_groups = ["extensions"]
    resources  = ["replicasets", "daemonsets"]
  }

  rule {
    verbs      = ["watch", "list"]
    api_groups = ["policy"]
    resources  = ["poddisruptionbudgets"]
  }

  rule {
    verbs      = ["watch", "list", "get"]
    api_groups = ["apps"]
    resources  = ["statefulsets", "replicasets", "daemonsets"]
  }

  rule {
    verbs      = ["watch", "list", "get"]
    api_groups = ["storage.k8s.io"]
    resources  = ["storageclasses"]
  }

  rule {
    verbs      = ["watch", "list", "get"]
    api_groups = ["storage.k8s.io"]
    resources  = ["csinodes"]
  }

  rule {
    verbs      = ["get", "list", "watch", "patch"]
    api_groups = ["batch", "extensions"]
    resources  = ["jobs"]
  }
}

resource "kubernetes_role" "cluster_autoscaler" {
  depends_on = [
    kubernetes_priority_class.high_priority_deployments,
    kubernetes_config_map.cluster_autoscaler_priority_expander,
  ]
  metadata {
    name      = "cluster-autoscaler"
    namespace = "kube-system"

    labels = {
      k8s-addon = "cluster-autoscaler.addons.k8s.io"
      k8s-app   = "cluster-autoscaler"
    }
  }

  rule {
    verbs      = ["create", "list", "watch"]
    api_groups = [""]
    resources  = ["configmaps"]
  }

  rule {
    verbs          = ["delete", "get", "update", "watch"]
    api_groups     = [""]
    resources      = ["configmaps"]
    resource_names = ["cluster-autoscaler-status", "cluster-autoscaler-priority-expander"]
  }
}

resource "kubernetes_cluster_role_binding" "cluster_autoscaler" {
  depends_on = [
    kubernetes_priority_class.high_priority_deployments,
    kubernetes_config_map.cluster_autoscaler_priority_expander,
  ]
  metadata {
    name = "cluster-autoscaler"

    labels = {
      k8s-addon = "cluster-autoscaler.addons.k8s.io"
      k8s-app   = "cluster-autoscaler"
    }
  }

  subject {
    kind      = "ServiceAccount"
    name      = "cluster-autoscaler"
    namespace = "kube-system"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-autoscaler"
  }
}

resource "kubernetes_role_binding" "cluster_autoscaler" {
  depends_on = [
    kubernetes_priority_class.high_priority_deployments,
    kubernetes_config_map.cluster_autoscaler_priority_expander,
  ]
  metadata {
    name      = "cluster-autoscaler"
    namespace = "kube-system"

    labels = {
      k8s-addon = "cluster-autoscaler.addons.k8s.io"
      k8s-app   = "cluster-autoscaler"
    }
  }

  subject {
    kind      = "ServiceAccount"
    name      = "cluster-autoscaler"
    namespace = "kube-system"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "cluster-autoscaler"
  }
}

resource "kubernetes_deployment" "cluster_autoscaler" {
  depends_on = [
    kubernetes_priority_class.high_priority_deployments,
    kubernetes_config_map.cluster_autoscaler_priority_expander,
    kubernetes_role_binding.cluster_autoscaler,
    kubernetes_cluster_role_binding.cluster_autoscaler,
  ]
  metadata {
    name      = "cluster-autoscaler"
    namespace = "kube-system"

    labels = {
      app = "cluster-autoscaler"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "cluster-autoscaler"
      }
    }

    template {
      metadata {
        labels = {
          app = "cluster-autoscaler"
        }
      }

      spec {
        automount_service_account_token = true
        volume {
          name = "ssl-certs"

          host_path {
            path = "/etc/ssl/certs/ca-bundle.crt"
          }
        }

        container {
          name    = "cluster-autoscaler"
          image   = "gcr.io/google-containers/cluster-autoscaler:v1.16.1"
          command = ["./cluster-autoscaler", "--v=4", "--stderrthreshold=info", "--cloud-provider=aws", "--skip-nodes-with-local-storage=false", "--expander=priority", "--balance-similar-node-groups", "--node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/${var.project}-${var.environment}"]

          resources {
            limits {
              cpu    = "100m"
              memory = "300Mi"
            }

            requests {
              cpu    = "100m"
              memory = "300Mi"
            }
          }

          volume_mount {
            name       = "ssl-certs"
            read_only  = true
            mount_path = "/etc/ssl/certs/ca-certificates.crt"
          }

          image_pull_policy = "Always"
        }

        node_selector = {
          service_node = "true"
        }

        service_account_name = "cluster-autoscaler"
        priority_class_name  = "high-priority-deployments"
      }
    }
  }
}

