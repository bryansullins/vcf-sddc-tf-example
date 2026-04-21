#!/usr/bin/env bash
set -euo pipefail

if [[ "${TRACE:-}" == "1" ]]; then
  set -x
fi

if [[ $# -lt 4 ]]; then
  echo "usage: $0 --fqdn <sddc_manager_fqdn> --username <username> --password <password> [--insecure true|false] [--task-limit N]" >&2
  exit 2
fi

host=""
username=""
password=""
insecure="false"
task_limit="50"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fqdn)
      host="$2"
      shift 2
      ;;
    --username)
      username="$2"
      shift 2
      ;;
    --password)
      password="$2"
      shift 2
      ;;
    --insecure)
      insecure="$2"
      shift 2
      ;;
    --task-limit)
      task_limit="$2"
      shift 2
      ;;
    *)
      echo "unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "${host}" || -z "${username}" || -z "${password}" ]]; then
  echo "missing required args: --fqdn, --username, --password" >&2
  exit 2
fi

base_url="https://${host}"
curl_tls_args=()
if [[ "${insecure}" == "true" ]]; then
  curl_tls_args+=("-k")
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required but not found in PATH" >&2
  exit 2
fi

token_payload=$(jq -n --arg username "${username}" --arg password "${password}" '{username: $username, password: $password}')

token_response=$(curl -sS "${curl_tls_args[@]}" \
  -H "Content-Type: application/json" \
  -X POST "${base_url}/v1/tokens" \
  -d "${token_payload}")

access_token=$(echo "${token_response}" | jq -r '.accessToken // empty')

if [[ -z "${access_token}" ]]; then
  error_message=$(echo "${token_response}" | jq -r '.message // .error // "authentication failed"')
  jq -n \
    --arg host "${host}" \
    --arg timestamp_utc "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    --arg error "${error_message}" \
    '{
      host: $host,
      timestamp_utc: $timestamp_utc,
      auth_ok: "false",
      domain_count: "0",
      failed_task_count: "0",
      failing_task_ids: "[]",
      error: $error
    }'
  exit 0
fi

auth_header=("Authorization: Bearer ${access_token}")

domains_response=$(curl -sS "${curl_tls_args[@]}" \
  -H "${auth_header[0]}" \
  "${base_url}/v1/domains")

tasks_response=$(curl -sS "${curl_tls_args[@]}" \
  -H "${auth_header[0]}" \
  "${base_url}/v1/tasks?pageSize=${task_limit}")

domain_count=$(echo "${domains_response}" | jq 'if type=="array" then length else (.elements // [] | length) end')
failed_task_count=$(echo "${tasks_response}" | jq '[((if type=="array" then . else (.elements // []) end)[]? | .status // .taskStatus // "") | ascii_upcase | select(. == "FAILED")] | length')
failing_task_ids=$(echo "${tasks_response}" | jq -c '[((if type=="array" then . else (.elements // []) end)[]? | select(((.status // .taskStatus // "") | ascii_upcase) == "FAILED") | (.id // .taskId // "unknown")]')

jq -n \
  --arg host "${host}" \
  --arg timestamp_utc "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
  --arg domain_count "${domain_count}" \
  --arg failed_task_count "${failed_task_count}" \
  --arg failing_task_ids "${failing_task_ids}" \
  '{
    host: $host,
    timestamp_utc: $timestamp_utc,
    auth_ok: "true",
    domain_count: $domain_count,
    failed_task_count: $failed_task_count,
    failing_task_ids: $failing_task_ids
  }'
