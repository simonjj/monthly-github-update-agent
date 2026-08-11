targetScope = 'resourceGroup'

@description('Azure region for all resources.')
param location string = 'centralus'

@secure()
@description('GitHub token used by GitHub CLI and Copilot CLI inside the sandbox.')
param githubToken string

@description('Object ID of the principal running azd.')
param deployerPrincipalId string

@allowed([
  'User'
  'ServicePrincipal'
])
param deployerPrincipalType string = 'User'

param sandboxGroupName string = 'github-aca-updater-group'
param sandboxName string = 'github-aca-updater'
param schedulerJobName string = 'github-aca-update-scheduler'
param schedule string = '0 0 1 * *'

var suffix = uniqueString(subscription().id, resourceGroup().id, 'monthly-github-update-agent')
var registryName = 'acagithubupdates${suffix}'
var environmentName = 'github-update-env-${suffix}'
var workspaceName = 'github-update-logs-${suffix}'
var imageRepository = 'monthly-github-update-orchestrator'
var bootstrapImage = 'mcr.microsoft.com/k8se/quickstart-jobs:latest'
var acrPullRoleDefinitionId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '7f951dda-4ed3-4680-a7ca-43fe172d538d'
)
var sandboxDataOwnerRoleDefinitionId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'c24cf47c-5077-412d-a19c-45202126392c'
)

resource sandboxGroup 'Microsoft.App/sandboxGroups@2026-02-01-preview' = {
  name: sandboxGroupName
  location: location
  properties: {}
}

resource registry 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: registryName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
  }
}

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  properties: {
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

resource environment 'Microsoft.App/managedEnvironments@2024-10-02-preview' = {
  name: environmentName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: workspace.properties.customerId
        sharedKey: workspace.listKeys().primarySharedKey
      }
    }
  }
}

resource schedulerJob 'Microsoft.App/jobs@2024-03-01' = {
  name: schedulerJobName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    environmentId: environment.id
    configuration: {
      triggerType: 'Schedule'
      replicaTimeout: 7200
      replicaRetryLimit: 1
      scheduleTriggerConfig: {
        cronExpression: schedule
        parallelism: 1
        replicaCompletionCount: 1
      }
      secrets: [
        {
          name: 'github-token'
          value: githubToken
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'orchestrator'
          image: bootstrapImage
          env: [
            {
              name: 'GITHUB_TOKEN'
              secretRef: 'github-token'
            }
            {
              name: 'AZURE_SUBSCRIPTION_ID'
              value: subscription().subscriptionId
            }
            {
              name: 'ACA_RESOURCE_GROUP'
              value: resourceGroup().name
            }
            {
              name: 'ACA_SANDBOX_GROUP'
              value: sandboxGroup.name
            }
            {
              name: 'ACA_REGION'
              value: location
            }
            {
              name: 'SANDBOX_NAME'
              value: sandboxName
            }
          ]
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
        }
      ]
    }
  }
}

resource schedulerAcrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(registry.id, schedulerJob.id, acrPullRoleDefinitionId)
  scope: registry
  properties: {
    roleDefinitionId: acrPullRoleDefinitionId
    principalId: schedulerJob.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource schedulerSandboxDataOwner 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(sandboxGroup.id, schedulerJob.id, sandboxDataOwnerRoleDefinitionId)
  scope: sandboxGroup
  properties: {
    roleDefinitionId: sandboxDataOwnerRoleDefinitionId
    principalId: schedulerJob.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource deployerSandboxDataOwner 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(sandboxGroup.id, deployerPrincipalId, sandboxDataOwnerRoleDefinitionId)
  scope: sandboxGroup
  properties: {
    roleDefinitionId: sandboxDataOwnerRoleDefinitionId
    principalId: deployerPrincipalId
    principalType: deployerPrincipalType
  }
}

output AZURE_CONTAINER_REGISTRY_NAME string = registry.name
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = registry.properties.loginServer
output AZURE_CONTAINER_APPS_JOB_NAME string = schedulerJob.name
output SANDBOX_GROUP_NAME string = sandboxGroup.name
output SANDBOX_NAME string = sandboxName
output SANDBOX_REGION string = location
output MONTHLY_SCHEDULE_UTC string = schedule
output ORCHESTRATOR_IMAGE_REPOSITORY string = imageRepository
