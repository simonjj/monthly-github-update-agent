$ErrorActionPreference = 'Stop'

function Get-AzdValue([string]$Name) {
    $value = azd env get-value $Name
    if (-not $value) {
        throw "Missing azd environment value '$Name'."
    }
    return $value.Trim()
}

$registryName = Get-AzdValue 'AZURE_CONTAINER_REGISTRY_NAME'
$registryEndpoint = Get-AzdValue 'AZURE_CONTAINER_REGISTRY_ENDPOINT'
$jobName = Get-AzdValue 'AZURE_CONTAINER_APPS_JOB_NAME'
$sandboxGroup = Get-AzdValue 'SANDBOX_GROUP_NAME'
$sandboxName = Get-AzdValue 'SANDBOX_NAME'
$region = Get-AzdValue 'SANDBOX_REGION'
$repository = Get-AzdValue 'ORCHESTRATOR_IMAGE_REPOSITORY'
$subscriptionId = Get-AzdValue 'AZURE_SUBSCRIPTION_ID'
$resourceGroup = Get-AzdValue 'AZURE_RESOURCE_GROUP'
$githubToken = Get-AzdValue 'GITHUB_TOKEN'
$imageTag = (Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmss')
$image = "$registryEndpoint/$repository`:$imageTag"

az acr build `
    --registry $registryName `
    --image "$repository`:$imageTag" `
    --file orchestrator/Containerfile `
    .
if ($LASTEXITCODE -ne 0) {
    throw 'ACR build failed.'
}

az containerapp job registry set `
    --name $jobName `
    --resource-group $resourceGroup `
    --server $registryEndpoint `
    --identity system `
    --output none
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to configure the scheduler job registry.'
}

az containerapp job update `
    --name $jobName `
    --resource-group $resourceGroup `
    --image $image `
    --output none
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to update the scheduler job image.'
}

$acaArgs = @(
    '--group', $sandboxGroup,
    '--subscription', $subscriptionId,
    '--resource-group', $resourceGroup,
    '--region', $region
)

$existingJson = aca sandbox list @acaArgs -o json
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to list existing sandboxes.'
}
$existing = $existingJson | ConvertFrom-Json
foreach ($sandbox in @($existing | Where-Object { $_.labels.name -eq $sandboxName })) {
    aca sandbox delete --id $sandbox.id @acaArgs --yes
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to delete stale sandbox '$($sandbox.id)'."
    }
}

aca sandbox create `
    --disk copilot `
    --cpu 2000m `
    --memory 4096Mi `
    --label "name=$sandboxName" `
    --label 'app=monthly-github-update-agent' `
    --label 'managed-by=azd' `
    --env "COPILOT_GITHUB_TOKEN=$githubToken" `
    --env "GH_TOKEN=$githubToken" `
    @acaArgs
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to create the ACA Sandbox.'
}

$createdJson = aca sandbox list @acaArgs -o json
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to read the newly created sandbox.'
}
$created = $createdJson | ConvertFrom-Json
$sandboxId = @($created | Where-Object { $_.labels.name -eq $sandboxName })[0].id
if (-not $sandboxId) {
    throw 'Sandbox creation succeeded without returning a sandbox ID.'
}

$sandboxReady = $false
for ($attempt = 1; $attempt -le 20; $attempt++) {
    $null = aca sandbox get --id $sandboxId @acaArgs 2>$null
    if ($LASTEXITCODE -eq 0) {
        $sandboxReady = $true
        break
    }
    Start-Sleep -Seconds 5
}
if (-not $sandboxReady) {
    throw "Sandbox '$sandboxId' did not become readable within 100 seconds."
}

aca sandbox lifecycle set --id $sandboxId --auto-suspend 600 @acaArgs
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to set the sandbox lifecycle policy.'
}

$archive = Join-Path ([System.IO.Path]::GetTempPath()) "monthly-agent-$sandboxId.tgz"
try {
    tar -C sandbox-workspace -czf $archive .
    if ($LASTEXITCODE -ne 0) {
        throw 'Failed to package the sandbox agent workspace.'
    }

    aca sandbox fs write `
        --id $sandboxId `
        --path /tmp/monthly-agent.tgz `
        --file $archive `
        @acaArgs
    if ($LASTEXITCODE -ne 0) {
        throw 'Failed to upload the agent workspace to the sandbox.'
    }

    aca sandbox exec `
        --id $sandboxId `
        -c 'rm -rf /work/monthly-agent && mkdir -p /work/monthly-agent && tar -xzf /tmp/monthly-agent.tgz -C /work/monthly-agent && copilot --version && gh --version' `
        @acaArgs
    if ($LASTEXITCODE -ne 0) {
        throw 'Failed to install or validate the agent workspace in the sandbox.'
    }
} finally {
    Remove-Item $archive -Force -ErrorAction SilentlyContinue
}

aca sandbox stop --id $sandboxId @acaArgs
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to stop the sandbox.'
}

Write-Host "Deployed orchestrator image $image and ACA Sandbox $sandboxName ($sandboxId)."
