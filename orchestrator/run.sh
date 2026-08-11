#!/usr/bin/env bash
set -euo pipefail

required_vars=(
  AZURE_SUBSCRIPTION_ID
  ACA_RESOURCE_GROUP
  ACA_SANDBOX_GROUP
  ACA_REGION
  SANDBOX_NAME
  GITHUB_TOKEN
)

for name in "${required_vars[@]}"; do
  if [[ -z "${!name:-}" ]]; then
    echo "Missing required environment variable: ${name}" >&2
    exit 1
  fi
done

aca_args=(
  --group "$ACA_SANDBOX_GROUP"
  --subscription "$AZURE_SUBSCRIPTION_ID"
  --resource-group "$ACA_RESOURCE_GROUP"
  --region "$ACA_REGION"
  --managed-identity system
)
selector="name=${SANDBOX_NAME}"
sandbox_id=""

stop_sandbox() {
  if [[ -z "$sandbox_id" ]]; then
    return
  fi

  if ! aca sandbox stop --id "$sandbox_id" "${aca_args[@]}"; then
    echo "Warning: failed to stop sandbox ${sandbox_id}." >&2
  fi
}
trap stop_sandbox EXIT

echo "Removing stale sandboxes with logical name ${SANDBOX_NAME}."
mapfile -t stale_ids < <(
  aca sandbox list "${aca_args[@]}" -o json \
    | jq -r --arg name "$SANDBOX_NAME" '.[] | select(.labels.name == $name) | .id'
)

for id in "${stale_ids[@]}"; do
  aca sandbox delete --id "$id" "${aca_args[@]}" --yes
done

echo "Creating ACA Sandbox ${SANDBOX_NAME}."
aca sandbox create \
  --disk copilot \
  --cpu 2000m \
  --memory 4096Mi \
  --label "name=${SANDBOX_NAME}" \
  --label "app=monthly-github-update-agent" \
  --label "managed-by=azd" \
  --env "COPILOT_GITHUB_TOKEN=${GITHUB_TOKEN}" \
  --env "GH_TOKEN=${GITHUB_TOKEN}" \
  "${aca_args[@]}"

sandbox_id="$(
  aca sandbox list "${aca_args[@]}" -o json \
    | jq -er --arg name "$SANDBOX_NAME" \
      'first(.[] | select(.labels.name == $name)) | .id'
)"

ready=false
for _ in {1..20}; do
  if aca sandbox get --id "$sandbox_id" "${aca_args[@]}" >/dev/null 2>&1; then
    ready=true
    break
  fi
  sleep 5
done

if [[ "$ready" != true ]]; then
  echo "Sandbox ${sandbox_id} did not become readable within 100 seconds." >&2
  exit 1
fi

aca sandbox lifecycle set \
  --id "$sandbox_id" \
  --auto-suspend 600 \
  "${aca_args[@]}"

tar -C /app/workspace -czf /tmp/monthly-agent.tgz .
aca sandbox fs write \
  --id "$sandbox_id" \
  --path /tmp/monthly-agent.tgz \
  --file /tmp/monthly-agent.tgz \
  "${aca_args[@]}"

aca sandbox exec \
  --id "$sandbox_id" \
  -c 'rm -rf /work/monthly-agent && mkdir -p /work/monthly-agent && tar -xzf /tmp/monthly-agent.tgz -C /work/monthly-agent' \
  "${aca_args[@]}"

echo "Running the monthly GitHub update agent in sandbox ${SANDBOX_NAME}."
aca sandbox exec \
  --id "$sandbox_id" \
  --working-directory /work/monthly-agent \
  -c 'printf "%s" "$GH_TOKEN" | gh auth login --hostname github.com --with-token; PROMPT="$(cat PROMPT.md)"; copilot -p "$PROMPT" --model auto --allow-all --no-ask-user --no-auto-update --secret-env-vars=COPILOT_GITHUB_TOKEN,GH_TOKEN --output-format text' \
  "${aca_args[@]}"

result="$(
  aca sandbox fs cat \
    --id "$sandbox_id" \
    --path /work/monthly-agent/result.json \
    "${aca_args[@]}"
)"

status="$(jq -er '.status | select(. == "published" or . == "already_exists")' <<<"$result")"
issue_url="$(jq -er '.issueUrl | select(startswith("https://github.com/microsoft/azure-container-apps/issues/"))' <<<"$result")"

echo "Monthly update ${status}: ${issue_url}"
