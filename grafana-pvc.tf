resource "kubernetes_persistent_volume_claim" "grafana" {
  depends_on = ["helm_release.termination-handler-exporter"]
  metadata {
    name      = "grafana"
    namespace = "monitoring"

    labels = {
      app = "grafana"
    }

    annotations = {
      "volume.beta.kubernetes.io/storage-provisioner" = "kubernetes.io/aws-ebs"
    }

##!!!    finalizers = ["kubernetes.io/pvc-protection"]
  }
  wait_until_bound = false
  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "1Gi"
      }
    }

    storage_class_name = "gp2-${local.pvc_az}"
  }
}

