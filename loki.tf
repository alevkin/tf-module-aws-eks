resource "kubernetes_namespace" "logging" {
  depends_on = [null_resource.init_tiller]
  metadata {
    annotations = {
      name = "logging"
    }
    name = "logging"
  }
}

resource "helm_release" "loki" {
  depends_on = [kubernetes_namespace.logging]
  name       = "loki"
  namespace  = "logging"
  chart      = "${path.module}/manifests/loki/loki/"

  set {
    name  = "ingress.annotations.external-dns\\.alpha\\.kubernetes\\.io/target"
    value = aws_route53_record.alb-route53-record.name
  }
  set {
    name  = "nodeSelector.failure-domain\\.beta\\.kubernetes\\.io/zone"
    value = local.pvc_az
  }
}

resource "helm_release" "promtail" {
  depends_on = [kubernetes_namespace.logging]
  name       = "promtail"
  namespace  = "logging"
  chart      = "${path.module}/manifests/loki/promtail/"

  set {
    name  = "ingress.annotations.external-dns\\.alpha\\.kubernetes\\.io/target"
    value = aws_route53_record.alb-route53-record.name
  }
  set {
    name  = "loki.serviceName"
    value = "loki"
  }
}

resource "local_file" "helmignoreloki" {
    content     = ".terragrunt-source-manifest"
    filename = "${path.module}/manifests/loki/loki-stack/.helmignore"
}

resource "helm_release" "loki-stack" {
  depends_on = [kubernetes_namespace.logging]
  name       = "loki-stack"
  namespace  = "logging"
  chart      = "${path.module}/manifests/loki/loki-stack/"

  set {
    name  = "ingress.annotations.external-dns\\.alpha\\.kubernetes\\.io/target"
    value = aws_route53_record.alb-route53-record.name
  }
  set {
    name  = "nodeSelector.failure-domain\\.beta\\.kubernetes\\.io/zone"
    value = local.pvc_az
  }
}