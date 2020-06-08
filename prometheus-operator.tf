resource "kubernetes_namespace" "monitoring" {
  depends_on = [kubernetes_storage_class.gp_2]
  metadata {
    annotations = {
      name = "monitoring"
    }
    name = "monitoring"
  }
}

## Local file with helmingore is workaround of https://github.com/gruntwork-io/terragrunt/issues/943
resource "local_file" "helmignore" {
    content     = ".terragrunt-source-manifest"
    filename = "${path.module}/manifests/monitoring/prometheus-operator-helm/.helmignore"
}

resource "helm_release" "prometheus-operator" {
  depends_on = [
#    null_resource.install_prom_crd,
    kubernetes_namespace.monitoring,
    local_file.helmignore,
  ]
  name      = "prometheus-operator"
  namespace = "monitoring"
  chart     = "${path.module}/manifests/monitoring/prometheus-operator-helm/"

  values = [
    file(
      "${path.module}/manifests_templates/monitoring/prometheus-operator-values.yaml",
    ),
  ]

  set {
    name  = "alertmanager.ingress.annotations.external-dns\\.alpha\\.kubernetes\\.io/target"
    value = aws_route53_record.alb-route53-record.name
  }
  set {
    name = "alertmanager.ingress.hosts"
    value = "{alertmanager.${join(",", var.root_domain)}}"
  }
  set {
    name  = "alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.storageClassName"
    value = "gp2-${local.pvc_az}"
  }
  set {
    name  = "alertmanager.alertmanagerSpec.nodeSelector.failure-domain\\.beta\\.kubernetes\\.io/zone"
    value = local.pvc_az
  }
  set {
    name  = "prometheusOperator.nodeSelector.failure-domain\\.beta\\.kubernetes\\.io/zone"
    value = local.pvc_az
  }
  set {
    name  = "prometheus.ingress.annotations.external-dns\\.alpha\\.kubernetes\\.io/target"
    value = aws_route53_record.alb-route53-record.name
  }
  set {
    name = "prometheus.ingress.hosts"
    value = "{prometheus.${join(",", var.root_domain)}}"
  }
  set {
    name  = "prometheus.prometheusSpec.nodeSelector.failure-domain\\.beta\\.kubernetes\\.io/zone"
    value = local.pvc_az
  }
  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName"
    value = "gp2-${local.pvc_az}"
  }
}

