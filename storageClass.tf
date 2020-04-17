resource "kubernetes_storage_class" "gp_2" {
  depends_on = ["null_resource.init_tiller"]
  metadata {
    name = "gp2-${local.pvc_az}"
  }
  
  storage_provisioner = "kubernetes.io/aws-ebs"
  parameters {
      type = "gp2"
      fsType = "ext4"
  }

  reclaim_policy      = "Retain"
  volume_binding_mode = "WaitForFirstConsumer"
}

##!!!
#allowedTopologies:
#  - matchLabelExpressions:
#    - key: failure-domain.beta.kubernetes.io/zone
#      values:
#      - '${availability_zone}'