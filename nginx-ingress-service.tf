resource "kubernetes_namespace" "ingress_nginx" {
  depends_on = ["null_resource.check_api", "local_file.kubeconfig_local"]
  metadata {
    name = "ingress-nginx"

    labels = {
      "app.kubernetes.io/name" = "ingress-nginx"

      "app.kubernetes.io/part-of" = "ingress-nginx"
    }
  }
}

resource "kubernetes_config_map" "tcp_services" {
  depends_on = ["null_resource.check_api", "local_file.kubeconfig_local", "kubernetes_namespace.ingress_nginx"]
  metadata {
    name      = "tcp-services"
    namespace = "ingress-nginx"

    labels = {
      "app.kubernetes.io/name" = "ingress-nginx"

      "app.kubernetes.io/part-of" = "ingress-nginx"
    }
  }
}

resource "kubernetes_config_map" "udp_services" {
  depends_on = ["null_resource.check_api", "local_file.kubeconfig_local", "kubernetes_namespace.ingress_nginx"]
  metadata {
    name      = "udp-services"
    namespace = "ingress-nginx"

    labels = {
      "app.kubernetes.io/name" = "ingress-nginx"

      "app.kubernetes.io/part-of" = "ingress-nginx"
    }
  }
}

resource "kubernetes_service_account" "nginx_ingress_serviceaccount" {
  depends_on = ["null_resource.check_api", "local_file.kubeconfig_local", "kubernetes_namespace.ingress_nginx"]
  metadata {
    name      = "nginx-ingress-serviceaccount"
    namespace = "ingress-nginx"

    labels = {
      "app.kubernetes.io/name" = "ingress-nginx"

      "app.kubernetes.io/part-of" = "ingress-nginx"
    }
  }
}

resource "kubernetes_cluster_role" "nginx_ingress_clusterrole" {
  depends_on = ["null_resource.check_api", "local_file.kubeconfig_local", "kubernetes_namespace.ingress_nginx"]
  metadata {
    name = "nginx-ingress-clusterrole"

    labels = {
      "app.kubernetes.io/name" = "ingress-nginx"

      "app.kubernetes.io/part-of" = "ingress-nginx"
    }
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = [""]
    resources  = ["configmaps", "endpoints", "nodes", "pods", "secrets"]
  }

  rule {
    verbs      = ["get"]
    api_groups = [""]
    resources  = ["nodes"]
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = [""]
    resources  = ["services"]
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = ["extensions"]
    resources  = ["ingresses"]
  }

  rule {
    verbs      = ["create", "patch"]
    api_groups = [""]
    resources  = ["events"]
  }

  rule {
    verbs      = ["update"]
    api_groups = ["extensions"]
    resources  = ["ingresses/status"]
  }
}

resource "kubernetes_role" "nginx_ingress_role" {
  depends_on = ["null_resource.check_api", "local_file.kubeconfig_local", "kubernetes_namespace.ingress_nginx"]
  metadata {
    name      = "nginx-ingress-role"
    namespace = "ingress-nginx"

    labels = {
      "app.kubernetes.io/name" = "ingress-nginx"

      "app.kubernetes.io/part-of" = "ingress-nginx"
    }
  }

  rule {
    verbs      = ["get"]
    api_groups = [""]
    resources  = ["configmaps", "pods", "secrets", "namespaces"]
  }

  rule {
    verbs          = ["get", "update"]
    api_groups     = [""]
    resources      = ["configmaps"]
    resource_names = ["ingress-controller-leader-nginx"]
  }

  rule {
    verbs      = ["create"]
    api_groups = [""]
    resources  = ["configmaps"]
  }

  rule {
    verbs      = ["get"]
    api_groups = [""]
    resources  = ["endpoints"]
  }
}

resource "kubernetes_role_binding" "nginx_ingress_role_nisa_binding" {
  depends_on = ["null_resource.check_api", "local_file.kubeconfig_local", "kubernetes_namespace.ingress_nginx"]
  metadata {
    name      = "nginx-ingress-role-nisa-binding"
    namespace = "ingress-nginx"

    labels = {
      "app.kubernetes.io/name" = "ingress-nginx"

      "app.kubernetes.io/part-of" = "ingress-nginx"
    }
  }

  subject {
    kind      = "ServiceAccount"
    name      = "nginx-ingress-serviceaccount"
    namespace = "ingress-nginx"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "nginx-ingress-role"
  }
}

resource "kubernetes_cluster_role_binding" "nginx_ingress_clusterrole_nisa_binding" {
  depends_on = ["null_resource.check_api", "local_file.kubeconfig_local", "kubernetes_namespace.ingress_nginx"]
  metadata {
    name = "nginx-ingress-clusterrole-nisa-binding"

    labels = {
      "app.kubernetes.io/name" = "ingress-nginx"

      "app.kubernetes.io/part-of" = "ingress-nginx"
    }
  }

  subject {
    kind      = "ServiceAccount"
    name      = "nginx-ingress-serviceaccount"
    namespace = "ingress-nginx"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "nginx-ingress-clusterrole"
  }
}

resource "kubernetes_daemonset" "nginx_ingress_controller" {
  depends_on = ["null_resource.check_api", "local_file.kubeconfig_local", "kubernetes_namespace.ingress_nginx"]
  metadata {
    name      = "nginx-ingress-controller"
    namespace = "ingress-nginx"

    labels = {
      "app.kubernetes.io/name" = "ingress-nginx"

      "app.kubernetes.io/part-of" = "ingress-nginx"
    }
  }

  spec {
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "ingress-nginx"

        "app.kubernetes.io/part-of" = "ingress-nginx"
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "ingress-nginx"

          "app.kubernetes.io/part-of" = "ingress-nginx"
        }

        annotations = {
          "prometheus.io/port" = "10254"

          "prometheus.io/scrape" = "true"
        }
      }

      spec {
        container {
          name  = "nginx-ingress-controller"
          image = "quay.io/kubernetes-ingress-controller/nginx-ingress-controller:0.24.0"
          args  = ["/nginx-ingress-controller", "--configmap=$(POD_NAMESPACE)/nginx-configuration", "--tcp-services-configmap=$(POD_NAMESPACE)/tcp-services", "--udp-services-configmap=$(POD_NAMESPACE)/udp-services", "--publish-service=$(POD_NAMESPACE)/ingress-nginx", "--annotations-prefix=nginx.ingress.kubernetes.io", "--default-backend-service=$(POD_NAMESPACE)/nginx-default-backend"]

          port {
            name           = "http"
            container_port = 80
          }

          port {
            name           = "https"
            container_port = 443
          }

          port {
            name           = "metrics"
            container_port = 10254
          }

          env {
            name = "POD_NAME"

            value_from {
              field_ref {
                field_path = "metadata.name"
              }
            }
          }

          env {
            name = "POD_NAMESPACE"

            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }

          liveness_probe {
            http_get {
              path   = "/healthz"
              port   = "metrics"
              scheme = "HTTP"
            }

            initial_delay_seconds = 10
            timeout_seconds       = 10
            period_seconds        = 10
            success_threshold     = 1
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path   = "/healthz"
              port   = "metrics"
              scheme = "HTTP"
            }

            timeout_seconds   = 10
            period_seconds    = 10
            success_threshold = 1
            failure_threshold = 3
          }

          security_context {
            run_as_user                = 33
            allow_privilege_escalation = true
          }
        }

        service_account_name = "nginx-ingress-serviceaccount"
      }
    }
  }
}



resource "kubernetes_service" "ingress_nginx" {
  depends_on = ["null_resource.check_api", "local_file.kubeconfig_local", "kubernetes_namespace.ingress_nginx"]
  metadata {
    name      = "ingress-nginx"
    namespace = "ingress-nginx"

    labels = {
      "app.kubernetes.io/name" = "ingress-nginx"

      "app.kubernetes.io/part-of" = "ingress-nginx"
    }
  }

  spec {
    port {
      name        = "http"
      port        = 80
      target_port = "http"
      node_port   = "${var.target_group_port}"
    }

    selector = {
      "app.kubernetes.io/name" = "ingress-nginx"

      "app.kubernetes.io/part-of" = "ingress-nginx"
    }

    type = "NodePort"
  }
}

resource "kubernetes_service" "ingress_nginx_metrics" {
  depends_on = ["null_resource.check_api", "local_file.kubeconfig_local", "kubernetes_namespace.ingress_nginx"]
  metadata {
    name      = "ingress-nginx-metrics"
    namespace = "ingress-nginx"

    labels = {
      app = "ingress-nginx"

      release = "nrw-monitoring"
    }
  }

  spec {
    port {
      name        = "metrics"
      protocol    = "TCP"
      port        = 10254
      target_port = "10254"
    }

    selector = {
      "app.kubernetes.io/name" = "ingress-nginx"

      "app.kubernetes.io/part-of" = "ingress-nginx"
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_config_map" "nginx_configuration" {
  depends_on = ["null_resource.check_api", "local_file.kubeconfig_local", "kubernetes_namespace.ingress_nginx"]
  metadata {
    name      = "nginx-configuration"
    namespace = "ingress-nginx"

    labels = {
      "app.kubernetes.io/name" = "ingress-nginx"

      "app.kubernetes.io/part-of" = "ingress-nginx"
    }
  }

  data = {
    proxy-real-ip-cidr = "0.0.0.0/0"

    use-forwarded-headers = "true"

    use-proxy-protocol = "false"
  }
}

resource "kubernetes_service" "nginx_default_backend" {
  depends_on = ["null_resource.check_api", "local_file.kubeconfig_local", "kubernetes_namespace.ingress_nginx"]
  metadata {
    name      = "nginx-default-backend"
    namespace = "ingress-nginx"

    labels = {
      k8s-addon = "ingress-nginx.addons.k8s.io"

      k8s-app = "default-http-backend"
    }
  }

  spec {
    port {
      port        = 80
      target_port = "http"
    }

    selector = {
      k8s-app = "default-http-backend"
    }
  }
}

resource "kubernetes_deployment" "nginx_default_backend" {
  depends_on = ["null_resource.check_api", "local_file.kubeconfig_local", "kubernetes_namespace.ingress_nginx"]
  metadata {
    name      = "nginx-default-backend"
    namespace = "ingress-nginx"

    labels = {
      k8s-addon = "ingress-nginx.addons.k8s.io"

      k8s-app = "default-http-backend"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "nginx-default-backend"

        k8s-addon = "ingress-nginx.addons.k8s.io"

        k8s-app = "default-http-backend"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx-default-backend"

          k8s-addon = "ingress-nginx.addons.k8s.io"

          k8s-app = "default-http-backend"
        }
      }

      spec {
        automount_service_account_token = true
        container {
          name  = "default-http-backend"
          image = "k8s.gcr.io/defaultbackend:1.3"

          port {
            name           = "http"
            container_port = 8080
            protocol       = "TCP"
          }

          resources {
            limits {
              cpu    = "10m"
              memory = "20Mi"
            }

            requests {
              cpu    = "1m"
              memory = "20Mi"
            }
          }

          liveness_probe {
            http_get {
              path   = "/healthz"
              port   = "8080"
              scheme = "HTTP"
            }

            initial_delay_seconds = 30
            timeout_seconds       = 5
          }
        }

        termination_grace_period_seconds = 60
      }
    }

    revision_history_limit = 10
  }
}

