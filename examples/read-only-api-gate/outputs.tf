output "api_health_summary" {
  description = "Summary of read-only API checks"
  value = {
    domain_count                  = local.domain_count
    failed_task_count             = local.failed_task_count
    auth_ok                       = local.auth_ok
    failing_task_ids              = try(jsondecode(lookup(data.external.sddc_probe.result, "failing_task_ids", "[]")), [])
    low_memory_domains            = local.low_memory_domains
    low_memory_warning_count      = length(local.low_memory_domains)
    memory_warning_threshold_pct  = var.min_memory_free_percent
    memory_free_warning_triggered = length(local.low_memory_domains) > 0
  }
}

output "domain_ids" {
  description = "List of domain IDs returned by /v1/domains"
  value       = try(jsondecode(lookup(data.external.sddc_probe.result, "domain_ids", "[]")), [])
}

output "domain_names" {
  description = "List of domain names returned by /v1/domains"
  value       = try(jsondecode(lookup(data.external.sddc_probe.result, "domain_names", "[]")), [])
}

output "domain_capacity" {
  description = "Best-effort current capacity object per domain from /v1/domains"
  value       = try(jsondecode(lookup(data.external.sddc_probe.result, "domain_capacity", "[]")), [])
}
