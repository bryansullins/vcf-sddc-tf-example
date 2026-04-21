output "api_health_summary" {
  description = "Summary of read-only API checks"
  value = {
    domain_count      = local.domain_count
    failed_task_count = local.failed_task_count
    auth_ok           = local.auth_ok
    failing_task_ids  = try(jsondecode(lookup(data.external.sddc_probe.result, "failing_task_ids", "[]")), [])
  }
}
