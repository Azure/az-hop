targetScope = 'subscription'

param azhopResourceGroupName string

@description('Azure region to use')
param location string = deployment().location

param deployGateway bool = true
param deployBastion bool = true
param publicIp bool = false
param deployVnet bool = true

@description('Autogenerate passwords and SSH key pair.')
param autogenerateSecrets bool = false

@description('SSH Public Key for the Virtual Machines.')
@secure()
param adminSshPublicKey string

@description('SSH Private Key for the Virtual Machines.')
@secure()
param adminSshPrivateKey string

@description('The Windows/Active Directory password.')
@secure()
param adminPassword string

@description('Password for the Slurm accounting admin user')
@secure()
param slurmAccountingAdminPassword string

var vnet = {
  tags: {
    NRMSBastion: ''
  }
  name: 'hpcvnet'
  cidr: '10.201.0.0/16'
  subnets: {
    bastion: {
      apply_nsg: false
      name: 'AzureBastionSubnet'
      cidr: '10.201.0.0/24'
    }
    frontend: {
      name: 'frontend'
      cidr: '10.201.1.0/24'
      service_endpoints: [
        'Microsoft.Sql'
        'Microsoft.Storage'
      ]
    }
    admin: {
      name: 'admin'
      cidr: '10.201.2.0/24'
      service_endpoints: [
        'Microsoft.KeyVault'
        'Microsoft.Sql'
        'Microsoft.Storage'
      ]
    }
    netapp: {
      apply_nsg: false
      name: 'netapp'
      cidr: '10.201.3.0/24'
      delegations: [
        'Microsoft.Netapp/volumes'
      ]
    }
    ad: {
      name: 'ad'
      cidr: '10.201.4.0/24'
    }
    compute: {
      name: 'compute'
      cidr: '10.201.5.0/24'
      service_endpoints: [
        'Microsoft.Storage'
      ]
    }
    gateway: {
      apply_nsg: false
      name: 'GatewaySubnet'
      cidr: '10.201.6.0/24'
    }
  }
}

resource azhopResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: azhopResourceGroupName
  location: location
}

module azhopSecrets './secrets.bicep' = if (autogenerateSecrets) {
  name: 'azhopSecrets'
  scope: azhopResourceGroup
  params: {
    location: location
  }
}

var secrets = (autogenerateSecrets) ? azhopSecrets.outputs : {
  adminSshPublicKey: adminSshPublicKey
  adminSshPrivateKey: adminSshPrivateKey
  adminPassword: adminPassword
  slurmAccountingAdminPassword: slurmAccountingAdminPassword
}

module azhopNetwork './network.bicep' = {
  name: 'azhopNetwork'
  scope: azhopResourceGroup
  params: {
    location: location
    deployGateway: deployGateway
    deployBastion: deployBastion
    publicIp: publicIp
    vnet: vnet
  }
}

var subnetIds = azhopNetwork.outputs.subnetIds

module azhopBastion './bastion.bicep' = if (deployBastion) {
  name: 'azhopBastion'
  scope: azhopResourceGroup
  params: {
    location: location
    subnetId: subnetIds.bastion
  }
}
