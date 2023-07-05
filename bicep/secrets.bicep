targetScope = 'resourceGroup'

param location string
param kvName string
param adminUser string
param dbAdminUser string
param identityId string

resource secrets 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'secrets'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityId}': {
      }
    }
  }
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.37.0'
    timeout: 'PT2H'
    retentionInterval: 'P1D'
    cleanupPreference: 'OnSuccess'
    scriptContent: replace(replace(replace('''
      #/bin/bash -e
      
      ssh-keygen -f "key"  -N ""

      az login -i

      az keyvault secret set --vault-name __KEYVAULT_NAME__ --name "__ADMIN_USER__-pubkey" --value "$(cat key.pub)" --query id -o tsv
      az keyvault secret set --vault-name __KEYVAULT_NAME__ --name "__ADMIN_USER__-privkey" --value "$(cat key)" --query id -o tsv
      az keyvault secret set --vault-name __KEYVAULT_NAME__ --name "__ADMIN_USER__-password" --value "$(openssl rand -base64 24)" --query id -o tsv
      az keyvault secret set --vault-name __KEYVAULT_NAME__ --name "__DB_ADMIN_USER__-password" --value "$(openssl rand -base64 24)" --query id -o tsv

      cat <<EOF >$AZ_SCRIPTS_OUTPUT_PATH
      {
        "adminSshPublicKey": "__ADMIN_USER__-pubkey",
        "adminSshPrivateKey": "__ADMIN_USER__-privkey",
        "adminPassword": "__ADMIN_USER__-password",
        "databaseAdminPassword": "__DB_ADMIN_USER__-password"
      }
      EOF

    ''', '__KEYVAULT_NAME__', kvName), '__ADMIN_USER__', adminUser), '__DB_ADMIN_USER__', dbAdminUser)
  }
}

output secrets object = {
  adminSshPublicKey: reference('secrets').outputs.adminSshPublicKey
  adminSshPrivateKey: reference('secrets').outputs.adminSshPrivateKey
  adminPassword: reference('secrets').outputs.adminPassword
  databaseAdminPassword: reference('secrets').outputs.databaseAdminPassword
}

