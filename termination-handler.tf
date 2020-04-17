resource "helm_release" "termination-handler" {
  depends_on = ["null_resource.init_tiller"]
  name       = "termination-handler"
  namespace = "kube-system"
  chart = "${path.module}/manifests/spot-termination-handler/"
}