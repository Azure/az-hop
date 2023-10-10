# https://www.techopedia.com/2/31981/networking/networking-hardware/dismissing-the-myth-that-active-directory-requires-microsoft-dns
resource "azurerm_private_dns_zone" "azhop_private_dns" {
  count               = local.create_dns_records? 1 : 0
  name                = local.domain_name
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
}

resource "azurerm_private_dns_zone_virtual_network_link" "azhop_dns_link" {
  count                 = local.create_dns_records? 1 : 0
  name                  = "az-hop"
  resource_group_name   = azurerm_private_dns_zone.azhop_private_dns[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.azhop_private_dns[0].name
  virtual_network_id    = local.create_vnet ? azurerm_virtual_network.azhop[0].id : data.azurerm_virtual_network.azhop[0].id
  registration_enabled  = false
}

## Domain Controlers entries
resource "azurerm_private_dns_a_record" "ad" {
  count               = local.create_dns_records? 1 : 0
  name                = values(local.domain_controlers)[0]
  resource_group_name = azurerm_private_dns_zone.azhop_private_dns[0].resource_group_name
  zone_name           = azurerm_private_dns_zone.azhop_private_dns[0].name
  ttl                 = 3600
  records             = local.create_dns_records? [local.domain_controller_ips[0]] : []
}

resource "azurerm_private_dns_a_record" "ad2" {
  count               = local.ad_ha ? 1 : 0
  name                = try(values(local.domain_controlers)[1], local.ad2_name)
  resource_group_name = azurerm_private_dns_zone.azhop_private_dns[0].resource_group_name
  zone_name           = azurerm_private_dns_zone.azhop_private_dns[0].name
  ttl                 = 3600
  records             = local.create_dns_records? [try(local.domain_controller_ips[1], local.domain_controller_ips[0])] : []
}

## Domain entries
resource "azurerm_private_dns_srv_record" "ldap_tcp" {
  count               = local.create_dns_records ? 1 : 0
  name                = "_ldap._tcp"
  resource_group_name = azurerm_private_dns_zone.azhop_private_dns[0].resource_group_name
  zone_name           = azurerm_private_dns_zone.azhop_private_dns[0].name
  ttl                 = 3600

  dynamic "record" {
    for_each = local.domain_controlers
    content {
    priority = 0
    weight   = 100
    port     = 389
    target   = "${record.value}.${local.domain_name}."
    }
  }
}
resource "azurerm_private_dns_srv_record" "kpasswd_tcp" {
  count               = local.create_dns_records ? 1 : 0
  name                = "_kpasswd._tcp"
  resource_group_name = azurerm_private_dns_zone.azhop_private_dns[0].resource_group_name
  zone_name           = azurerm_private_dns_zone.azhop_private_dns[0].name
  ttl                 = 3600
  dynamic "record" {
    for_each = local.domain_controlers
    content {
    priority = 0
    weight   = 100
    port     = 464
    target   = "${record.value}.${local.domain_name}."
    }
  }
}
resource "azurerm_private_dns_srv_record" "kerberos_tcp" {
  count               = local.create_dns_records ? 1 : 0
  name                = "_kerberos._tcp"
  resource_group_name = azurerm_private_dns_zone.azhop_private_dns[0].resource_group_name
  zone_name           = azurerm_private_dns_zone.azhop_private_dns[0].name
  ttl                 = 3600
  dynamic "record" {
    for_each = local.domain_controlers
    content {
    priority = 0
    weight   = 100
    port     = 88
    target   = "${record.value}.${local.domain_name}."
    }
  }
}
resource "azurerm_private_dns_srv_record" "gc_tcp" {
  count               = local.create_dns_records ? 1 : 0
  name                = "_gc._tcp"
  resource_group_name = azurerm_private_dns_zone.azhop_private_dns[0].resource_group_name
  zone_name           = azurerm_private_dns_zone.azhop_private_dns[0].name
  ttl                 = 3600
  dynamic "record" {
    for_each = local.domain_controlers
    content {
    priority = 0
    weight   = 100
    port     = 3268
    target   = "${record.value}.${local.domain_name}."
    }
  }
}
resource "azurerm_private_dns_srv_record" "kerberos_udp" {
  count               = local.create_dns_records ? 1 : 0
  name                = "_kerberos._udp"
  resource_group_name = azurerm_private_dns_zone.azhop_private_dns[0].resource_group_name
  zone_name           = azurerm_private_dns_zone.azhop_private_dns[0].name
  ttl                 = 3600
  dynamic "record" {
    for_each = local.domain_controlers
    content {
    priority = 0
    weight   = 100
    port     = 88
    target   = "${record.value}.${local.domain_name}."
    }
  }
}
resource "azurerm_private_dns_srv_record" "kpasswd_udp" {
  count               = local.create_dns_records ? 1 : 0
  name                = "_kpasswd._udp"
  resource_group_name = azurerm_private_dns_zone.azhop_private_dns[0].resource_group_name
  zone_name           = azurerm_private_dns_zone.azhop_private_dns[0].name
  ttl                 = 3600
  dynamic "record" {
    for_each = local.domain_controlers
    content {
    priority = 0
    weight   = 100
    port     = 464
    target   = "${record.value}.${local.domain_name}."
    }
  }
}

# MSDCS specific entries
resource "azurerm_private_dns_srv_record" "ldap_tcpdc_msdcs" {
  count               = local.create_dns_records ? 1 : 0
  name                = "_ldap._tcp.dc._msdcs"
  resource_group_name = azurerm_private_dns_zone.azhop_private_dns[0].resource_group_name
  zone_name           = azurerm_private_dns_zone.azhop_private_dns[0].name
  ttl                 = 3600
  dynamic "record" {
    for_each = local.domain_controlers
    content {
    priority = 0
    weight   = 100
    port     = 389
    target   = "${record.value}.${local.domain_name}."
    }
  }
}
resource "azurerm_private_dns_srv_record" "kerberos_tcpdc_msdcs" {
  count               = local.create_dns_records ? 1 : 0
  name                = "_kerberos._tcp.dc._msdcs"
  resource_group_name = azurerm_private_dns_zone.azhop_private_dns[0].resource_group_name
  zone_name           = azurerm_private_dns_zone.azhop_private_dns[0].name
  ttl                 = 3600
  dynamic "record" {
    for_each = local.domain_controlers
    content {
    priority = 0
    weight   = 100
    port     = 88
    target   = "${record.value}.${local.domain_name}."
    }
  }
}
resource "azurerm_private_dns_srv_record" "ldap_tcp_gc_msdcs" {
  count               = local.create_dns_records ? 1 : 0
  name                = "_ldap._tcp.gc._msdcs"
  resource_group_name = azurerm_private_dns_zone.azhop_private_dns[0].resource_group_name
  zone_name           = azurerm_private_dns_zone.azhop_private_dns[0].name
  ttl                 = 3600
  dynamic "record" {
    for_each = local.domain_controlers
    content {
    priority = 0
    weight   = 100
    port     = 3268
    target   = "${record.value}.${local.domain_name}."
    }
  }
}
resource "azurerm_private_dns_srv_record" "ldap_tcppdc_msdcs" {
  count               = local.create_dns_records ? 1 : 0
  name                = "_ldap._tcp.pdc._msdcs"
  resource_group_name = azurerm_private_dns_zone.azhop_private_dns[0].resource_group_name
  zone_name           = azurerm_private_dns_zone.azhop_private_dns[0].name
  ttl                 = 3600
  record {
    priority = 0
    weight   = 100
    port     = 389
    target   = "${values(local.domain_controlers)[0]}.${local.domain_name}."
  }
}
resource "azurerm_private_dns_srv_record" "ldapdefault-first-site-name_sitesdc_msdcs" {
  count               = local.create_dns_records ? 1 : 0
  name                = "_ldap.default-first-site-name._sites.dc._msdcs"
  resource_group_name = azurerm_private_dns_zone.azhop_private_dns[0].resource_group_name
  zone_name           = azurerm_private_dns_zone.azhop_private_dns[0].name
  ttl                 = 3600
  dynamic "record" {
    for_each = local.domain_controlers
    content {
    priority = 0
    weight   = 100
    port     = 389
    target   = "${record.value}.${local.domain_name}."
    }
  }
}
resource "azurerm_private_dns_srv_record" "kerberosdefault-first-site-name_sitesdc_msdcs" {
  count               = local.create_dns_records ? 1 : 0
  name                = "_kerberos.default-first-site-name._sites.dc._msdcs"
  resource_group_name = azurerm_private_dns_zone.azhop_private_dns[0].resource_group_name
  zone_name           = azurerm_private_dns_zone.azhop_private_dns[0].name
  ttl                 = 3600
  dynamic "record" {
    for_each = local.domain_controlers
    content {
    priority = 0
    weight   = 100
    port     = 88
    target   = "${record.value}.${local.domain_name}."
    }
  }
}
resource "azurerm_private_dns_srv_record" "ldapdefault-first-site-name_sitesgc_msdcs" {
  count               = local.create_dns_records ? 1 : 0
  name                = "_ldap.default-first-site-name._sites.gc._msdcs"
  resource_group_name = azurerm_private_dns_zone.azhop_private_dns[0].resource_group_name
  zone_name           = azurerm_private_dns_zone.azhop_private_dns[0].name
  ttl                 = 3600
  dynamic "record" {
    for_each = local.domain_controlers
    content {
    priority = 0
    weight   = 100
    port     = 3268
    target   = "${record.value}.${local.domain_name}."
    }
  }
}

#adding explicit moved blocks to ensure clean migrations for previously deployed environments
#https://developer.hashicorp.com/terraform/language/modules/develop/refactoring#enabling-count-or-for_each-for-a-resource
# moved { 
#   from = azurerm_private_dns_a_record.ad
#   to   = azurerm_private_dns_a_record.ad[0]
# }

# moved {
#   from = azurerm_private_dns_srv_record.ldap_tcp
#   to = azurerm_private_dns_srv_record.ldap_tcp[0]
# }

# moved {
#   from = azurerm_private_dns_srv_record.kpasswd_tcp
#   to   = azurerm_private_dns_srv_record.kpasswd_tcp[0]
# }

# moved {
#   from = azurerm_private_dns_srv_record.kerberos_tcp
#   to   = azurerm_private_dns_srv_record.kerberos_tcp[0]
# }

# moved {
#   from = azurerm_private_dns_srv_record.gc_tcp
#   to   = azurerm_private_dns_srv_record.gc_tcp[0]
# }

# moved {
#   from = azurerm_private_dns_srv_record.kerberos_udp
#   to   = azurerm_private_dns_srv_record.kerberos_udp[0]
# }

# moved {
#   from = azurerm_private_dns_srv_record.kpasswd_udp
#   to   = azurerm_private_dns_srv_record.kpasswd_udp[0]
# }

# moved {
#   from = azurerm_private_dns_srv_record.ldap_tcpdc_msdcs
#   to   = azurerm_private_dns_srv_record.ldap_tcpdc_msdcs[0]
# }

# moved {
#   from = azurerm_private_dns_srv_record.ldap_tcp_gc_msdcs
#   to   = azurerm_private_dns_srv_record.ldap_tcp_gc_msdcs[0]
# }

# moved {
#   from = azurerm_private_dns_srv_record.ldap_tcppdc_msdcs
#   to   = azurerm_private_dns_srv_record.ldap_tcppdc_msdcs[0]
# }

# moved {
#   from = azurerm_private_dns_srv_record.ldapdefault-first-site-name_sitesdc_msdcs
#   to   = azurerm_private_dns_srv_record.ldapdefault-first-site-name_sitesdc_msdcs[0]
# }

# moved {
#   from = azurerm_private_dns_srv_record.kerberosdefault-first-site-name_sitesdc_msdcs
#   to   = azurerm_private_dns_srv_record.kerberosdefault-first-site-name_sitesdc_msdcs[0]
# }

# moved {
#   from = azurerm_private_dns_srv_record.ldapdefault-first-site-name_sitesgc_msdcs
#   to   = azurerm_private_dns_srv_record.ldapdefault-first-site-name_sitesgc_msdcs[0]
# }

