#!/usr/bin/env sh
set -eu

for tool in az azd aca; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Required command '$tool' is not installed." >&2
    exit 1
  fi
done

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "Set GITHUB_TOKEN to a token for simonjj with Copilot access and issue write permission." >&2
  exit 1
fi

subscription_id="$(az account show --query id -o tsv)"
account_type="$(az account show --query user.type -o tsv)"
account_name="$(az account show --query user.name -o tsv)"

if [ "$account_type" = "servicePrincipal" ]; then
  principal_type="ServicePrincipal"
  principal_id="$(az ad sp show --id "$account_name" --query id -o tsv)"
else
  principal_type="User"
  principal_id="$(az ad signed-in-user show --query id -o tsv)"
fi

az group create --name prodish-stuff --location centralus --output none
for namespace in Microsoft.App Microsoft.ContainerRegistry Microsoft.OperationalInsights; do
  az provider register --namespace "$namespace" --wait
done
az extension add --name containerapp --upgrade --only-show-errors

azd env set AZURE_SUBSCRIPTION_ID "$subscription_id" >/dev/null
azd env set AZURE_RESOURCE_GROUP prodish-stuff >/dev/null
azd env set AZURE_LOCATION centralus >/dev/null
azd env set AZURE_PRINCIPAL_ID "$principal_id" >/dev/null
azd env set AZURE_PRINCIPAL_TYPE "$principal_type" >/dev/null
azd env set GITHUB_TOKEN "$GITHUB_TOKEN" >/dev/null

echo "Provisioning target fixed to resource group prodish-stuff in Central US."
