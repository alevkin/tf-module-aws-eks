provider "kubernetes" {
  config_path = "${path.cwd}/${module.eks.kubeconfig_filename}"
}

provider "helm" {
  kubernetes {
    config_path = "${path.cwd}/${module.eks.kubeconfig_filename}"
  }
}

resource "null_resource" "eks_cluster" {
  triggers = {
    cluster_id = "${module.eks.cluster_id}"
  }
}

data "aws_subnet" "pvc_subnet" {
  id = "${var.private_subnets[0]}"
}

locals {
  pvc_az = "${var.monitoring_availability_zone == "" ? data.aws_subnet.pvc_subnet.availability_zone : var.monitoring_availability_zone}"
}

resource "null_resource" "check_api" {
  depends_on = ["null_resource.eks_cluster"]

  provisioner "local-exec" {
    working_dir = "${path.module}"

    command = <<EOS
exit_code=1
while [ $exit_code -ne 0 ]; do \
exit_code=$(kubectl get pods --all-namespaces --kubeconfig ${path.cwd}/${module.eks.kubeconfig_filename} | echo &?); \
sleep 5; \
done;
EOS

    interpreter = ["${var.local_exec_interpreter}"]
  }
}