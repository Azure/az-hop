targetScope = 'resourceGroup'

param location string = resourceGroup().location

resource secrets 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'secrets'
  location: location
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.37.0'
    timeout: 'PT2H'
    retentionInterval: 'P1D'
    cleanupPreference: 'OnSuccess'
    scriptContent: '''
      #/bin/bash -e
      
      ssh-keygen -f "key"  -N ""

      cat <<EOF >$AZ_SCRIPTS_OUTPUT_PATH
      {
        "adminSshPublicKey": "$(cat key.pub)",
        "adminSshPrivateKey": "$(cat key)",
        "adminPassword": "$(openssl rand -base64 24)",
        "slurmAccountingAdminPassword": "$(openssl rand -base64 24)"
      }
      EOF

    '''
  }
}

output secrets object = {
  adminSshPublicKey: reference('secrets').outputs.adminSshPublicKey
  adminSshPrivateKey: reference('secrets').outputs.adminSshPrivateKey
  adminPassword: reference('secrets').outputs.adminPassword
  domainPassword: reference('secrets').outputs.adminPassword
  slurmAccountingAdminPassword: reference('secrets').outputs.slurmAccountingAdminPassword
}

