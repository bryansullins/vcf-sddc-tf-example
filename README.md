# vcf-sddc-tf-example

Read-only Terraform example you can use in a CI/CD pipeline (or blog post) to
validate VMware Cloud Foundation (VCF) 9.0.1 SDDC Manager health via API.

The example is intentionally non-disruptive:
- It **does not create, update, or delete** anything in VCF.
- It only calls read endpoints and turns the response into a Terraform
  `check` gate.
- You run `terraform plan` as the test step.

## Included example

Path: `examples/read-only-api-gate`

What it tests:
1. API authentication to SDDC Manager (`POST /v1/tokens`)
2. Domain inventory is reachable (`GET /v1/domains`)
3. No failed tasks in the returned task list (`GET /v1/tasks?pageSize=<task_limit>`)
4. Captures domain metadata for reporting:
   - domain IDs
   - domain names
   - best-effort capacity fields returned on each domain object
5. Warns when domain memory free percent is below threshold (default 15%)

If a check fails, `terraform plan` exits non-zero, which makes it useful as a
"pipeline quality gate" style step.

## Quick start

```bash
cd examples/read-only-api-gate
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your SDDC Manager details

terraform init
terraform plan
```

## Example `terraform.tfvars`

```hcl
sddc_manager_fqdn = "sddc-manager.lab.local"
username          = "administrator@vsphere.local"
password          = "replace-me"

# set true for self-signed cert labs
insecure = true

# gate threshold: fail if more than this many failed tasks are returned
max_failed_tasks = 0
task_limit       = 50

# warning threshold: memory free percent lower than this triggers a check warning
min_memory_free_percent = 15
```

## CI snippet (generic)

```bash
terraform -chdir=examples/read-only-api-gate init -input=false
terraform -chdir=examples/read-only-api-gate plan -input=false -no-color
```

No `apply` step is required for this pattern.

## Extra output for blog/demo reporting

The `api_health_summary` output now includes:
- `domain_ids` (list of IDs)
- `domain_names` (list of names)
- `domain_capacity` (per-domain best-effort capacity summary from API payload)
- `low_memory_domains` (domains below free-memory threshold)

Show it with:

```bash
terraform output api_health_summary
```
