# https://www.techopedia.com/2/31981/networking/networking-hardware/dismissing-the-myth-that-active-directory-requires-microsoft-dns
resource "azurerm_private_dns_zone" "azhop_private_dns" {
  name                = "hpc.azure"
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
}

resource "azurerm_private_dns_zone_virtual_network_link" "azhop_dns_link" {
  name                  = "az-hop"
  resource_group_name   = azurerm_private_dns_zone.azhop_private_dns.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.azhop_private_dns.name
  virtual_network_id    = local.create_vnet ? azurerm_virtual_network.azhop[0].id : data.azurerm_virtual_network.azhop[0].id
  registration_enabled  = false
}

## Domain Controlers entries
resource "azurerm_private_dns_a_record" "ad" {
  count               =  local.create_ad ? 1 : 0
  name                = "ad"
  resource_group_name = azurerm_private_dns_zone.azhop_private_dns.resource_group_name
  zone_name           = azurerm_private_dns_zone.azhop_private_dns.name
  ttl                 = 3600
  records             = [azurerm_network_interface.ad-nic[0].private_ip_address]
}

resource "azurerm_private_dns_a_record" "ad2" {
  count               = local.ad_ha ? 1 : 0
  name                = "ad2"
  resource_group_name = azurerm_private_dns_zone.azhop_private_dns.resource_group_name
  zone_name           = azurerm_private_dns_zone.azhop_private_dns.name
  ttl                 = 3600
  records             = [azurerm_network_interface.ad2-nic[0].private_ip_address]
}

## Domain entries
resource "azurerm_private_dns_srv_record" "ldap_tcp" {
  count               =  local.create_ad ? 1 : 0
  name                = "_ldap._tcp"
  resource_group_name = azurerm_private_dns_zone.azhop_private_dns.resource_group_name
  zone_name           = azurerm_private_dns_zone.azhop_private_dns.name
  ttl                 = 3600

  dynamic "record" {
    for_each = local.domain_controlers
    content {
    priority = 0
    weight   = 100
    port     = 389
    target   = "${record.value}.hpc.azure."
    }
  }
}
resource "azurerm_private_dns_srv_record" "kpasswd_tcp" {
  count               =  local.create_ad ? 1 : 0
  name                = "_kpasswd._tcp"
  resource_group_name = azurerm_private_dns_zone.azhop_private_dns.resource_group_name
  zone_name           = azurerm_private_dns_zone.azhop_private_dns.name
  ttl                 = 3600
  dynamic "record" {
    for_each = local.domain_controlers
    content {
    priority = 0
    weight   = 100
    port     = 464
    target   = "${record.value}.hpc.azure."
    }
  }
}
resource "azurerm_private_dns_srv_record" "kerberos_tcp" {
  count               =  local.create_ad ? 1 : 0
  name                = "_kerberos._tcp"
  resource_group_name = azurerm_private_dns_zone.azhop_private_dns.resource_group_name
  zone_name           = azurerm_private_dns_zone.azhop_private_dns.name
  ttl                 = 3600
  dynamic "record" {
    for_each = local.domain_controlers
    content {
    priority = 0
    weight   = 100
    port     = 88
    target   = "${record.value}.hpc.azure."
    }
  }
}
resource "azurerm_private_dns_srv_record" "gc_tcp" {
  count               =  local.create_ad ? 1 : 0
  name                = "_gc._tcp"
  resource_group_name = azurerm_private_dns_zone.azhop_private_dns.resource_group_name
  zone_name           = azurerm_private_dns_zone.azhop_private_dns.name
  ttl                 = 3600
  dynamic "record" {
    for_each = local.domain_controlers
    content {
    priority = 0
    weight   = 100
    port     = 3268
    target   = "${record.value}.hpc.azure."
    }
  }
}
resource "azurerm_private_dns_srv_record" "kerberos_udp" {
  count               =  local.create_ad ? 1 : 0
  name                = "_kerberos._udp"
  resource_group_name = azurerm_private_dns_zone.azhop_private_dns.resource_group_name
  zone_name           = azurerm_private_dns_zone.azhop_private_dns.name
  ttl                 = 3600
  dynamic "record" {
    for_each = local.domain_controlers
    content {
    priority = 0
    weight   = 100
    port     = 88
    target   = "${record.value}.hpc.azure."
    }
  }
}
resource "azurerm_private_dns_srv_record" "kpasswd_udp" {
  count               =  local.create_ad ? 1 : 0
  name                = "_kpasswd._udp"
  resource_group_name = azurerm_private_dns_zone.azhop_private_dns.resource_group_name
  zone_name           = azurerm_private_dns_zone.azhop_private_dns.name
  ttl                 = 3600
  dynamic "record" {
    for_each = local.domain_controlers
    content {
    priority = 0
    weight   = 100
    port     = 464
    target   = "${record.value}.hpc.azure."
    }
  }
}

# MSDCS specific entries
resource "azurerm_private_dns_srv_record" "ldap_tcpdc_msdcs" {
  count               =  local.create_ad ? 1 : 0
  name                = "_ldap._tcp.dc._msdcs"
  resource_group_name = azurerm_private_dns_zone.azhop_private_dns.resource_group_name
  zone_name           = azurerm_private_dns_zone.azhop_private_dns.name
  ttl                 = 3600
  dynamic "record" {
    for_each = local.domain_controlers
    content {
    priority = 0
    weight   = 100
    port     = 389
    target   = "${record.value}.hpc.azure."
    }
  }
}
resource "azurerm_private_dns_srv_record" "kerberos_tcpdc_msdcs" {
  count               =  local.create_ad ? 1 : 0
  name                = "_kerberos._tcp.dc._msdcs"
  resource_group_name = azurerm_private_dns_zone.azhop_private_dns.resource_group_name
  zone_name           = azurerm_private_dns_zone.azhop_private_dns.name
  ttl                 = 3600
  dynamic "record" {
    for_each = local.domain_controlers
    content {
    priority = 0
    weight   = 100
    port     = 88
    target   = "${record.value}.hpc.azure."
    }
  }
}
resource "azurerm_private_dns_srv_record" "ldap_tcp_gc_msdcs" {
  count               =  local.create_ad ? 1 : 0
  name                = "_ldap._tcp.gc._msdcs"
  resource_group_name = azurerm_private_dns_zone.azhop_private_dns.resource_group_name
  zone_name           = azurerm_private_dns_zone.azhop_private_dns.name
  ttl                 = 3600
  dynamic "record" {
    for_each = local.domain_controlers
    content {
    priority = 0
    weight   = 100
    port     = 3268
    target   = "${record.value}.hpc.azure."
    }
  }
}
resource "azurerm_private_dns_srv_record" "ldap_tcppdc_msdcs" {
  count               =  local.create_ad ? 1 : 0
  name                = "_ldap._tcp.pdc._msdcs"
  resource_group_name = azurerm_private_dns_zone.azhop_private_dns.resource_group_name
  zone_name           = azurerm_private_dns_zone.azhop_private_dns.name
  ttl                 = 3600
  record {
    priority = 0
    weight   = 100
    port     = 389
    target   = "ad.hpc.azure."
  }
}
resource "azurerm_private_dns_srv_record" "ldapdefault-first-site-name_sitesdc_msdcs" {
  count               =  local.create_ad ? 1 : 0
  name                = "_ldap.default-first-site-name._sites.dc._msdcs"
  resource_group_name = azurerm_private_dns_zone.azhop_private_dns.resource_group_name
  zone_name           = azurerm_private_dns_zone.azhop_private_dns.name
  ttl                 = 3600
  dynamic "record" {
    for_each = local.domain_controlers
    content {
    priority = 0
    weight   = 100
    port     = 389
    target   = "${record.value}.hpc.azure."
    }
  }
}
resource "azurerm_private_dns_srv_record" "kerberosdefault-first-site-name_sitesdc_msdcs" {
  count               =  local.create_ad ? 1 : 0
  name                = "_kerberos.default-first-site-name._sites.dc._msdcs"
  resource_group_name = azurerm_private_dns_zone.azhop_private_dns.resource_group_name
  zone_name           = azurerm_private_dns_zone.azhop_private_dns.name
  ttl                 = 3600
  dynamic "record" {
    for_each = local.domain_controlers
    content {
    priority = 0
    weight   = 100
    port     = 88
    target   = "${record.value}.hpc.azure."
    }
  }
}
resource "azurerm_private_dns_srv_record" "ldapdefault-first-site-name_sitesgc_msdcs" {
  count               =  local.create_ad ? 1 : 0
  name                = "_ldap.default-first-site-name._sites.gc._msdcs"
  resource_group_name = azurerm_private_dns_zone.azhop_private_dns.resource_group_name
  zone_name           = azurerm_private_dns_zone.azhop_private_dns.name
  ttl                 = 3600
  dynamic "record" {
    for_each = local.domain_controlers
    content {
    priority = 0
    weight   = 100
    port     = 3268
    target   = "${record.value}.hpc.azure."
    }
  }
}
