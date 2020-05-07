resource "kubernetes_namespace" "logs" {
  depends_on = ["null_resource.check_api", "local_file.kubeconfig_local"]
  metadata {
    annotations = {
      name = "logs"
    }
    name = "logs"
  }
}

resource "helm_release" "fluentd" {
  depends_on = ["null_resource.init_tiller", "kubernetes_namespace.logs"]
  name       = "fluentd"
  namespace = "logs"
  chart = "${path.module}/manifests/logs_fluend_cloudwatch/"

  values = [
    "${file("${path.module}/manifests_templates/fluentd_values.yaml")}"
  ]

  set {
    name  = "awsRegion"
    value = "${data.aws_region.current.name}"
  }
  set {
    name  = "logGroupName"
    value = "${var.project}-${var.environment}-container-logs"
  }
  set {
    name  = "awsRole"
    value = "${module.eks.worker_iam_role_name}"
  }
}