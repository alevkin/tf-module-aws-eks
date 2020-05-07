resource "kubernetes_priority_class" "high_priority_deployments" {
  depends_on = ["null_resource.check_api"]
  metadata {
    name = "high-priority-deployments"
  }

  value       = 1000000000
  description = "This priority class should be used for high priority pods only(autoscaler, runner manager pods, etc.)."
}

