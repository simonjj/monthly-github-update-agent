#!/usr/bin/env bash
set -euo pipefail

get_azd_value() {
  local value
  value="$(azd env get-value "$1")"
  if [[ -z "$value" ]]; then
    echo "Missing azd environment value '$1'." >&2
    exit 1
  fi
  printf '%s' "$value"
}

registry_name="$(get_azd_value AZURE_CONTAINER_REGISTRY_NAME)"
registry_endpoint="$(get_azd_value AZURE_CONTAINER_REGISTRY_ENDPOINT)"
job_name="$(get_azd_value AZURE_CONTAINER_APPS_JOB_NAME)"
sandbox_group="$(get_azd_value SANDBOX_GROUP_NAME)"
sandbox_name="$(get_azd_value SANDBOX_NAME)"
region="$(get_azd_value SANDBOX_REGION)"
repository="$(get_azd_value ORCHESTRATOR_IMAGE_REPOSITORY)"
subscription_id="$(get_azd_value AZURE_SUBSCRIPTION_ID)"
resource_group="$(get_azd_value AZURE_RESOURCE_GROUP)"
github_token="$(get_azd_value GITHUB_TOKEN)"
image_tag="$(date -u +%Y%m%d%H%M%S)"
image="${registry_endpoint}/${repository}:${image_tag}"

az acr build \
  --registry "$registry_name" \
  --image "${repository}:${image_tag}" \
  --file orchestrator/Containerfile \
  .

az containerapp job registry set \
  --name "$job_name" \
  --resource-group "$resource_group" \
  --server "$registry_endpoint" \
  --identity system \
  --output none

az containerapp job update \
  --name "$job_name" \
  --resource-group "$resource_group" \
  --image "$image" \
  --output none

existing_ids="$(
  aca sandbox list \
    --group "$sandbox_group" \
    --subscription "$subscription_id" \
    --resource-group "$resource_group" \
    --region "$region" \
    -o json \
    | jq -r --arg name "$sandbox_name" '.[] | select(.labels.name == $name) | .id'
)"

while IFS= read -r id; do
  if [[ -n "$id" ]]; then
    aca sandbox delete \
      --id "$id" \
      --group "$sandbox_group" \
      --subscription "$subscription_id" \
      --resource-group "$resource_group" \
      --region "$region" \
      --yes
  fi
done <<<"$existing_ids"

aca sandbox create \
  --group "$sandbox_group" \
  --disk copilot \
  --cpu 2000m \
  --memory 4096Mi \
  --label "name=${sandbox_name}" \
  --label "app=monthly-github-update-agent" \
  --label "managed-by=azd" \
  --env "COPILOT_GITHUB_TOKEN=${github_token}" \
  --env "GH_TOKEN=${github_token}" \
  --subscription "$subscription_id" \
  --resource-group "$resource_group" \
  --region "$region"

sandbox_id="$(
  aca sandbox list \
    --group "$sandbox_group" \
    --subscription "$subscription_id" \
    --resource-group "$resource_group" \
    --region "$region" \
    -o json \
    | jq -er --arg name "$sandbox_name" \
      'first(.[] | select(.labels.name == $name)) | .id'
)"

ready=false
for _ in $(seq 1 20); do
  if aca sandbox get \
    --id "$sandbox_id" \
    --group "$sandbox_group" \
    --subscription "$subscription_id" \
    --resource-group "$resource_group" \
    --region "$region" \
    >/dev/null 2>&1; then
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
  --group "$sandbox_group" \
  --auto-suspend 600 \
  --subscription "$subscription_id" \
  --resource-group "$resource_group" \
  --region "$region"

archive="$(mktemp)"
trap 'rm -f "$archive"' EXIT
tar -C sandbox-workspace -czf "$archive" .
aca sandbox fs write \
  --id "$sandbox_id" \
  --group "$sandbox_group" \
  --path /tmp/monthly-agent.tgz \
  --file "$archive" \
  --subscription "$subscription_id" \
  --resource-group "$resource_group" \
  --region "$region"
aca sandbox exec \
  --id "$sandbox_id" \
  --group "$sandbox_group" \
  -c 'rm -rf /work/monthly-agent && mkdir -p /work/monthly-agent && tar -xzf /tmp/monthly-agent.tgz -C /work/monthly-agent && copilot --version && gh --version' \
  --subscription "$subscription_id" \
  --resource-group "$resource_group" \
  --region "$region"

aca sandbox stop \
  --id "$sandbox_id" \
  --group "$sandbox_group" \
  --subscription "$subscription_id" \
  --resource-group "$resource_group" \
  --region "$region"

echo "Deployed orchestrator image ${image} and ACA Sandbox ${sandbox_name} (${sandbox_id})."
