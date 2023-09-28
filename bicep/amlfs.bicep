targetScope = 'resourceGroup'

param location string
param subnetId string

resource fileSystem 'Microsoft.StorageCache/amlFileSystems@2021-11-01-preview' = {
  name: 'amlfs'
  location: location
  sku: {
    name: 'AMLFS-Durable-Premium-250'
  }
  properties: {
    storageCapacityTiB: 8
    zones: [ 1 ]
    filesystemSubnet: subnetId
    maintenanceWindow: {
      dayOfWeek: 'Friday'
      timeOfDay: '21:00'
    }
  }
}

output lustre_mgs string = fileSystem.properties.mgsAddress
