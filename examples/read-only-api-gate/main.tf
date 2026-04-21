data "external" "sddc_probe" {
  program = [
    "bash",
    "${path.module}/scripts/sddc_probe.sh",
    "--fqdn",
    var.sddc_manager_fqdn,
    "--username",
    var.username,
    "--password",
    var.password,
    "--insecure",
    var.insecure ? "true" : "false",
    "--task-limit",
    tostring(var.task_limit),
    "--memory-free-warning-percent",
    tostring(var.min_memory_free_percent)
  ]
}

locals {
  domain_count      = tonumber(lookup(data.external.sddc_probe.result, "domain_count", "0"))
  failed_task_count = tonumber(lookup(data.external.sddc_probe.result, "failed_task_count", "0"))
  auth_ok           = lower(lookup(data.external.sddc_probe.result, "auth_ok", "false")) == "true"
  low_memory_domains = try(
    jsondecode(lookup(data.external.sddc_probe.result, "memory_capacity_warnings", "[]")),
    []
  )
  low_memory_warning_count = tonumber(lookup(data.external.sddc_probe.result, "memory_warning_count", "0"))
}

check "sddc_manager_authentication" {
  assert {
    condition     = local.auth_ok
    error_message = "SDDC Manager authentication failed. Check fqdn/credentials/cert settings."
  }
}

check "domain_inventory_reachable" {
  assert {
    condition     = local.domain_count >= 1
    error_message = "No workload/management domains returned by GET /v1/domains."
  }
}

check "failed_tasks_threshold" {
  assert {
    condition     = local.failed_task_count <= var.max_failed_tasks
    error_message = "Failed task count (${local.failed_task_count}) exceeded threshold (${var.max_failed_tasks})."
  }
}

check "domain_memory_free_threshold" {
  assert {
    condition     = local.low_memory_warning_count == 0
    error_message = "Memory free warning (< ${var.min_memory_free_percent}%): ${jsonencode(local.low_memory_domains)}"
  }
}
