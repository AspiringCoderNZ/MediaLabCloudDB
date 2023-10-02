resource "azurerm_subnet" "default" {
  address_prefixes     = ["10.0.2.0/24"]
  name                 = "subnet-Lan"
  resource_group_name  = "LanIAC-rg"
  virtual_network_name = "LanIAC-vnet"
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "fs"

    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}
# Enables you to manage Private DNS zones within Azure DNS
resource "azurerm_private_dns_zone" "default" {
  name                = "LanIAC.mysql.database.azure.com"
  resource_group_name = "LanIAC-rg"
}

# Enables you to manage Private DNS zone Virtual Network Links
resource "azurerm_private_dns_zone_virtual_network_link" "default" {
  name                  = "mysqlfsVnetZoneLanIAC.com"
  private_dns_zone_name = "LanIAC.mysql.database.azure.com"
  resource_group_name   = "LanIAC-rg"
  virtual_network_id    = "/subscriptions/9c8e79dd-f0cb-4acb-ad8c-80e9987585a5/resourceGroups/LanIAC-rg/providers/Microsoft.Network/virtualNetworks/LanIAC-vnet"
  depends_on = [azurerm_private_dns_zone.default]
}

resource "azurerm_mysql_flexible_database" "default" {
  name                = "lan-mysqlfs-iac601"
  resource_group_name = "LanIAC-rg"
  server_name         = azurerm_mysql_flexible_server.default.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
  depends_on = [ azurerm_mysql_flexible_server.default ]
}


# Manages the MySQL Flexible Server
resource "azurerm_mysql_flexible_server" "default" {
  location                     = "AustraliaEast"
  name                         = "lanmysqlfs601iac"
  resource_group_name          = "LanIAC-rg"
  administrator_login          = "azureuser"
  administrator_password       = "Aspire2International@91"
  backup_retention_days        = 7
  delegated_subnet_id          = azurerm_subnet.default.id
  geo_redundant_backup_enabled = false
  private_dns_zone_id          = azurerm_private_dns_zone.default.id
  sku_name                     = "GP_Standard_D2ds_v4"
  version                      = "8.0.21"
  zone                         = "1"

  high_availability {
    mode                      = "ZoneRedundant"
    standby_availability_zone = "2"
  }
  maintenance_window {
    day_of_week  = 0
    start_hour   = 8
    start_minute = 0
  }
  storage {
    iops    = 360
    size_gb = 20
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.default]
}
