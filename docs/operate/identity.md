# Managing Identities in Az-Hop
Managed identities for Azure resources eliminate the need to manage credentials in code. Applications can use managed identities to obtain Azure AD tokens without having to manage any credentials. In Az-Hop, you can leverage user-assigned managed identities against your compute infrastructure.

## Enabling Managed Identities for Compute  
To use managed identities against the compute, you can use an existing identity or have az-hop create one for you. Below are the steps for each scenario. 

### Create and Use an Identity
For az-hop to create a user-assigned managed identity and use it against the compute you will need to enable the feature in the configuration file: 

```yml
# Enable the assignment of a managed identity to compute VMs managed by CycleCloud. 
# You can create an identity and optionally specify a name for the identity to be created or use an existing identity.
compute_vm_identity:
  create: true
  # An existing user assigned identity can be used instead. 
  # The name & resource group of the target identity will need to be specified if using an existing identity.
  # If you opt for creating an identity, you can specify a name for the identity to be created, but do not need to specify the resource group.
  #name: 
  #resource_group: ''
```

If the feature is enabled, az-hop will create the identity and name it "compute-mi". You can specify the name of the identity that is created, by providing the name in the config file: 

```yml
# Enable the assignment of a managed identity to compute VMs managed by CycleCloud. 
# You can create an identity and optionally specify a name for the identity to be created or use an existing identity.
compute_vm_identity:
  create: true
  # An existing user assigned identity can be used instead. 
  # The name & resource group of the target identity will need to be specified if using an existing identity.
  # If you opt for creating an identity, you can specify a name for the identity to be created, but do not need to specify the resource group.
  name: compute-mi-name
  #resource_group: 
```

Note, when you create user-assigned managed identities, only alphanumeric characters (0-9, a-z, and A-Z) and the hyphen (-) are supported. For the assignment to work properly, the name is limited to 24 characters. Az-Hop will check that the identity's name meets this criteria. If it does not, the deployment's validation step will fail. 

### Use an Existing Identity
For az-hop to use an existing user-assigned managed identity against the compute nodes, you will need to specify the following in the config file:
- The name of the target identity
- The resource group of the target identity 

Additionally, you will need to indicate that you do not want az-hop to create the identity. Below is an example of how to apply the configuration to az-hop: 

```yml
# Enable the assignment of a managed identity to compute VMs managed by CycleCloud. 
# You can create an identity and optionally specify a name for the identity to be created or use an existing identity.
compute_vm_identity:
  create: false
  # An existing user assigned identity can be used instead. 
  # The name & resource group of the target identity will need to be specified if using an existing identity.
  # If you opt for creating an identity, you can specify a name for the identity to be created, but do not need to specify the resource group.
  name: compute-mi-name
  resource_group: compute_mi_rg
```