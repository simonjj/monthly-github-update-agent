$ErrorActionPreference = 'Stop'

foreach ($tool in @('az', 'azd', 'aca')) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        throw "Required command '$tool' is not installed."
    }
}

if (-not $env:GITHUB_TOKEN) {
    throw 'Set GITHUB_TOKEN to a token for simonjj with Copilot access and permission to create issues in microsoft/azure-container-apps.'
}

$account = az account show | ConvertFrom-Json
if (-not $account.id) {
    throw 'Azure CLI is not authenticated.'
}

$principalType = if ($account.user.type -eq 'servicePrincipal') { 'ServicePrincipal' } else { 'User' }
$principalId = if ($principalType -eq 'ServicePrincipal') {
    az ad sp show --id $account.user.name --query id -o tsv
} else {
    az ad signed-in-user show --query id -o tsv
}

if (-not $principalId) {
    throw 'Could not resolve the Azure principal object ID.'
}

az group create --name prodish-stuff --location centralus --output none
foreach ($namespace in @('Microsoft.App', 'Microsoft.ContainerRegistry', 'Microsoft.OperationalInsights')) {
    az provider register --namespace $namespace --wait
}
az extension add --name containerapp --upgrade --only-show-errors

azd env set AZURE_SUBSCRIPTION_ID $account.id | Out-Null
azd env set AZURE_RESOURCE_GROUP prodish-stuff | Out-Null
azd env set AZURE_LOCATION centralus | Out-Null
azd env set AZURE_PRINCIPAL_ID $principalId.Trim() | Out-Null
azd env set AZURE_PRINCIPAL_TYPE $principalType | Out-Null
azd env set GITHUB_TOKEN $env:GITHUB_TOKEN | Out-Null

Write-Host 'Provisioning target fixed to resource group prodish-stuff in Central US.'
