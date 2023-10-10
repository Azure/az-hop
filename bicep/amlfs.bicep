targetScope = 'resourceGroup'

param location string
param name string
param subnetId string
@allowed([
  'AMLFS-Durable-Premium-40'
  'AMLFS-Durable-Premium-125'
  'AMLFS-Durable-Premium-250'
  'AMLFS-Durable-Premium-500'
])
param sku string
@description('''
The step sizes are dependent on the SKU.
- AMLFS-Durable-Premium-40: 48TB
- AMLFS-Durable-Premium-125: 16TB
- AMLFS-Durable-Premium-250: 8TB
- AMLFS-Durable-Premium-500: 4TB
''')
param capacity int

resource fileSystem 'Microsoft.StorageCache/amlFileSystems@2023-05-01' = {
  name: name
  location: location
  sku: {
    name: sku
  }
  zones: [ '1' ]
  properties: {
    storageCapacityTiB: capacity
    filesystemSubnet: subnetId
    maintenanceWindow: {
      dayOfWeek: 'Saturday'
      timeOfDayUTC: '23:00'
    }
  }
}

output lustre_mgs string = fileSystem.properties.clientInfo.mgsAddress
