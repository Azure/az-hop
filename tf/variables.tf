variable AzureEnvironment {
  default = "AZUREPUBLICCLOUD"
}

variable KeyVaultSuffix {
  default = "vault.azure.net"
}

variable BlobStorageSuffix {
  default = "blob.core.windows.net"
}

variable CreatedBy {
  default = ""
}

variable tenant_id {
  type = string
  description = "The azure tenant id the user is logged in"
  default = ""
}

variable logged_user_objectId {
  type = string
  description = "The azure user logged object id"
  default = ""
}