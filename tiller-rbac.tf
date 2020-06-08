resource "kubernetes_service_account" "tiller" {
  depends_on = [
    null_resource.check_api,
    aws_autoscaling_group.spot-asg,
  ]
  metadata {
    name      = "tiller"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "tiller" {
  depends_on = [
    null_resource.check_api,
    aws_autoscaling_group.spot-asg,
  ]
  metadata {
    name = "tiller"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "tiller"
    namespace = "kube-system"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
}

resource "null_resource" "init_tiller" {
  depends_on = [
    null_resource.check_api,
    aws_autoscaling_group.spot-asg,
    kubernetes_service_account.tiller,
    kubernetes_cluster_role_binding.tiller,
  ]

  provisioner "local-exec" {
    working_dir = path.module

    command = <<EOS
helm init --wait --service-account tiller --history-max 10 --kubeconfig ${path.cwd}/${module.eks.kubeconfig_filename}; \
sleep 5;
EOS


#    interpreter = var.local_exec_interpreter
  }
}

