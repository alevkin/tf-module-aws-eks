resource "helm_release" "grafana" {
  depends_on = [kubernetes_persistent_volume_claim.grafana]
  name       = "grafana"
  namespace  = "monitoring"
  chart      = "${path.module}/manifests/monitoring/grafana-helm/"

  values = [
    file(
      "${path.module}/manifests_templates/monitoring/grafana-values.yaml",
    ),
  ]

  set {
    name  = "ingress.annotations.external-dns\\.alpha\\.kubernetes\\.io/target"
    value = aws_route53_record.alb-route53-record.name
  }
  set {
    name  = "ingress.hosts"
    value = "{${join(",", var.root_domain)}}"
  }
  set {
    name  = "nodeSelector.failure-domain\\.beta\\.kubernetes\\.io/zone"
    value = local.pvc_az
  }
}

