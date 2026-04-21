variable "sddc_manager_fqdn" {
  description = "FQDN or IP of the VCF SDDC Manager endpoint (without protocol)."
  type        = string
}

variable "username" {
  description = "SSO user for SDDC Manager API authentication."
  type        = string
}

variable "password" {
  description = "Password for the SSO user."
  type        = string
  sensitive   = true
}

variable "insecure" {
  description = "Skip TLS verification for lab/self-signed cert environments."
  type        = bool
  default     = false
}

variable "max_failed_tasks" {
  description = "Gate threshold: fail check when failed task count exceeds this value."
  type        = number
  default     = 0
}

variable "task_limit" {
  description = "How many tasks to fetch when evaluating failed task count."
  type        = number
  default     = 50
}

variable "min_memory_free_percent" {
  description = "Warn when any domain reports memory free percent below this threshold."
  type        = number
  default     = 15
}
