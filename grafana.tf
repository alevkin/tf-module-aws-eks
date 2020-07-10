resource "kubernetes_secret" "grafana-ldap-toml" {
  count = var.grafana_ldap_toml == null ? 0 : 1

  metadata {
    name      = "grafana-ldap-toml"
    namespace = "monitoring"
  }

  data = {
    ldap-toml = var.grafana_ldap_toml
  }
}

resource "helm_release" "grafana" {
  depends_on = [kubernetes_persistent_volume_claim.grafana, kubernetes_secret.grafana-ldap-toml]
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
    value = "{grafana.${join(",", var.root_domain)}}"
  }
  set {
    name  = "nodeSelector.failure-domain\\.beta\\.kubernetes\\.io/zone"
    value = local.pvc_az
  }
  set {
    name  = "grafana\\.ini.auth\\.ldap.enabled"
    value = var.grafana_ldap_toml == null ? false : true
  }
  set {
    name  = "ldap.existingSecret"
    value = var.grafana_ldap_toml == null ? "" : "grafana-ldap-toml"
  }
}
