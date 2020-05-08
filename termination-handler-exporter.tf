resource "helm_release" "termination-handler-exporter" {
  depends_on = ["helm_release.prometheus-operator"]
  name = "termination-handler-exporter"
  namespace = "kube-system"
  chart = "${path.module}/manifests/spot-termination-exporter/"
}
