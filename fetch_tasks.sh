#!/bin/bash
# Fetches a project's open tasks from odoo.com as raw JSON. Reads
# ODOO_API_TOKEN and ODOO_PROJECT_ID from the environment -- never from an
# argument -- so the token never needs to appear in a Claude tool call.
set -euo pipefail

if [[ -z "${ODOO_API_TOKEN:-}" ]]; then
  echo "ODOO_API_TOKEN is not set. See this skill's README for one-time setup." >&2
  exit 1
fi
if [[ -z "${ODOO_PROJECT_ID:-}" ]]; then
  echo "ODOO_PROJECT_ID is not set. See this skill's README for one-time setup." >&2
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

response=$(curl -sS -w '\n%{http_code}' -X POST "https://www.odoo.com/json/2/project.task/search_read" \
  -H "Authorization: Bearer ${ODOO_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "${body}")

http_code=$(tail -n1 <<< "$response")
payload=$(sed '$d' <<< "$response")

if [[ "$http_code" != "200" ]]; then
  echo "odoo.com returned HTTP $http_code: $payload" >&2
  exit 1
fi

echo "$payload"
