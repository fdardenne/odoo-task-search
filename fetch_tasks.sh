#!/bin/bash
# Fetches a project's open tasks from odoo.com as raw JSON. Reads the API
# token from the OS keychain at call time -- never from the environment or an
# argument -- so it isn't inherited by other processes and never needs to
# appear in a Claude tool call. ODOO_PROJECT_ID (not a secret) comes from the
# environment.
set -euo pipefail

KEYCHAIN_SERVICE="odoo-api-token"

if [[ -z "${ODOO_PROJECT_ID:-}" ]]; then
  echo "ODOO_PROJECT_ID is not set. See this skill's README for one-time setup." >&2
  exit 1
fi

read_token() {
  if command -v security >/dev/null 2>&1; then
    security find-generic-password -s "$KEYCHAIN_SERVICE" -w 2>/dev/null
  elif command -v secret-tool >/dev/null 2>&1; then
    secret-tool lookup service "$KEYCHAIN_SERVICE" 2>/dev/null
  else
    return 1
  fi
}

if ! token=$(read_token) || [[ -z "$token" ]]; then
  echo "No Odoo API token found in the keychain (service \"$KEYCHAIN_SERVICE\"). See this skill's README for one-time setup." >&2
  exit 1
fi

include_closed=false
for arg in "$@"; do
  if [[ "$arg" == "--include-closed" ]]; then
    include_closed=true
  fi
done

if [[ "$include_closed" == true ]]; then
  domain="[[\"project_id\",\"=\",${ODOO_PROJECT_ID}]]"
else
  domain="[[\"project_id\",\"=\",${ODOO_PROJECT_ID}],[\"state\",\"not in\",[\"1_done\",\"1_canceled\"]]]"
fi

body="{\"domain\": ${domain}, \"fields\": [\"name\", \"description\", \"stage_id\"], \"limit\": 2000}"

# The auth header is fed through stdin (-H @-) so the token never shows up in
# curl's command line, where other processes could see it via `ps`.
response=$(printf 'Authorization: Bearer %s\n' "$token" | curl -sS -w '\n%{http_code}' \
  -X POST "https://www.odoo.com/json/2/project.task/search_read" \
  -H @- \
  -H "Content-Type: application/json" \
  -d "${body}")
unset token

http_code=$(tail -n1 <<< "$response")
payload=$(sed '$d' <<< "$response")

if [[ "$http_code" != "200" ]]; then
  echo "odoo.com returned HTTP $http_code: $payload" >&2
  exit 1
fi

echo "$payload"
