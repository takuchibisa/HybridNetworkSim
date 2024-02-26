# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.89.0"
    }
  }
}


provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "HybridNetworkSimRG"
  location = "Australia Southeast"

  tags = {
    Environment = "HybridNetworkSim"

  }
}

#### Create a Azure virtual network ####
resource "azurerm_virtual_network" "vnet" {
  name          = "azurevnet"
  address_space = ["10.0.0.0/16"]

  location            = "australiasoutheast"
  resource_group_name = azurerm_resource_group.rg.name
}

##### Create subnets for Vnet ####
resource "azurerm_subnet" "webappsubnet" {
  name                 = "WebAppSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "databasesubnet" {
  name                 = "DatabaseSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]

  enforce_private_link_service_network_policies = true
}

resource "azurerm_subnet" "adminsubnet" {
  name                 = "AdminSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_subnet" "vpngatewaysubnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.4.0/24"]
}

resource "azurerm_subnet" "bastionsubnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.5.0/25"]
}



##### Create Network Security Groups for Subnets ####

resource "azurerm_network_security_group" "webappnsg" {
  name                = "webapp-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "subnetnsg" {
  name                = "subnet-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

}

resource "azurerm_network_security_rule" "inbound_allow_rdp" {
  network_security_group_name = azurerm_network_security_group.subnetnsg.name
  resource_group_name         = azurerm_resource_group.rg.name
  name                        = "Inbound_Allow_Bastion_RDP"
  priority                    = 500
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = azurerm_subnet.bastionsubnet.address_prefixes[0]
  destination_address_prefixes  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

resource "azurerm_network_security_rule" "inbound_allow_ssh" {
  network_security_group_name = azurerm_network_security_group.subnetnsg.name
  resource_group_name         = azurerm_resource_group.rg.name
  name                        = "Inbound_Allow_Bastion_SSH"
  priority                    = 510
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = azurerm_subnet.bastionsubnet.address_prefixes[0]
  destination_address_prefixes  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

resource "azurerm_network_security_rule" "inbound_deny_all" {
  network_security_group_name = azurerm_network_security_group.subnetnsg.name
  resource_group_name         = azurerm_resource_group.rg.name
  name                        = "Inbound_Deny_Any_Any"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefixes  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

resource "azurerm_network_security_rule" "outbound_allow_subnet" {
  network_security_group_name = azurerm_network_security_group.subnetnsg.name
  resource_group_name         = azurerm_resource_group.rg.name
  name                        = "Outbound_Allow_Subnet_Any"
  priority                    = 500
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefixes      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  destination_address_prefixes  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

resource "azurerm_network_security_rule" "outbound_deny_all" {
  network_security_group_name = azurerm_network_security_group.subnetnsg.name
  resource_group_name         = azurerm_resource_group.rg.name
  name                        = "Outbound_Deny_Any_Any"
  priority                    = 1000
  direction                   = "Outbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefixes     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  destination_address_prefix  = "*"
}

resource "azurerm_subnet_network_security_group_association" "webappsubnet_association" {
  network_security_group_id = azurerm_network_security_group.subnetnsg.id
  subnet_id                 = azurerm_subnet.webappsubnet.id
}
resource "azurerm_subnet_network_security_group_association" "databasesubnet_association" {
  network_security_group_id = azurerm_network_security_group.subnetnsg.id
  subnet_id                 = azurerm_subnet.databasesubnet.id
}

resource "azurerm_subnet_network_security_group_association" "adminsubnet_association" {
  network_security_group_id = azurerm_network_security_group.subnetnsg.id
  subnet_id                 = azurerm_subnet.adminsubnet.id
}


##### Create Virtual Machines ####

# Create an SSH key
resource "tls_private_key" "vm_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
# Create network interfaces
resource "azurerm_network_interface" "nic_vm_webapp" {
  name                = "nic_vm_webapp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "nic_vm_webapp-configuration"
    subnet_id                     = azurerm_subnet.webappsubnet.id
    private_ip_address_allocation = "Dynamic"
  }
}
resource "azurerm_network_interface" "nic_vm_webapp2" {
  name                = "nic_vm_webapp2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "nic_vm_webapp2-configuration"
    subnet_id                     = azurerm_subnet.webappsubnet.id
    private_ip_address_allocation = "Dynamic"
  }
}
resource "azurerm_network_interface" "nic_vm_database" {
  name                = "nic_vm_database"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "nic_vm_database-configuration"
    subnet_id                     = azurerm_subnet.databasesubnet.id
    private_ip_address_allocation = "Dynamic"
  }
}
resource "azurerm_network_interface" "nic_vm_admin" {
  name                = "nic_vm_admin"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "nic_vm_admin-configuration"
    subnet_id                     = azurerm_subnet.adminsubnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create virtual machines
resource "azurerm_linux_virtual_machine" "vm_webapp" {
  name                  = "vm-webapp"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic_vm_webapp.id]
  size                  = "Standard_B1ls"

  os_disk {
    name                 = "disk-os-webapp"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "vm-webapp"
  admin_username                  = "vm-azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "vm-azureuser"
    public_key = tls_private_key.vm_ssh.public_key_openssh
  }
}
resource "azurerm_linux_virtual_machine" "vm_webapp2" {
  name                  = "vm-webapp2"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic_vm_webapp2.id]
  size                  = "Standard_B1ls"

  os_disk {
    name                 = "disk-os-webapp2"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "vm-webapp2"
  admin_username                  = "vm-azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "vm-azureuser"
    public_key = tls_private_key.vm_ssh.public_key_openssh
  }
}

resource "azurerm_linux_virtual_machine" "vm_database" {
  name                  = "vm-dabatase"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic_vm_database.id]
  size                  = "Standard_B1ls"

  os_disk {
    name                 = "disk-os-database"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "vm-database"
  admin_username                  = "vm-azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "vm-azureuser"
    public_key = tls_private_key.vm_ssh.public_key_openssh
  }
}

resource "azurerm_linux_virtual_machine" "vm_admin" {
  name                  = "vm-admin"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic_vm_admin.id]
  size                  = "Standard_B1ls"

  os_disk {
    name                 = "disk-os-admin"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "vm-admin"
  admin_username                  = "vm-azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "vm-azureuser"
    public_key = tls_private_key.vm_ssh.public_key_openssh
  }
}
#Create Azure Bastion Host and PIP
resource "azurerm_public_ip" "bastion_pip" {
  name                = "pip-bastion"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion_host" {
  name                = "bastion-host"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  scale_units         = 2

  copy_paste_enabled     = true
  file_copy_enabled      = true
  shareable_link_enabled = true
  tunneling_enabled      = true

  ip_configuration {
    name                 = "config-01"
    subnet_id            = azurerm_subnet.bastionsubnet.id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }
}


#### Create VPN Gateway and PIP ####

# Create Public IP for VPN Gateway
resource "azurerm_public_ip" "pip" {
  name                = "gatewaypip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  allocation_method = "Dynamic"
}
# Define the Azure VPN Gateway

resource "azurerm_virtual_network_gateway" "vpngateway" {
  name                = "azurevnet_vpn_gateway"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "Basic"
  active_active       = false
  enable_bgp          = false
  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.vpngatewaysubnet.id
  }
  vpn_client_configuration {
    address_space = ["10.1.0.0/24"]
  }
}

#### Create SQL Database and Private Endpoint ####
# Define the Azure SQL Server
resource "azurerm_mssql_server" "sqlprivateserver" {
  name                         = "sqlprivateserver"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = "P@ssw0rd1234"
  
}
# Define the Azure SQL Database
resource "azurerm_mssql_database" "database" {

  name           = "database"
  server_id      = azurerm_mssql_server.sqlprivateserver.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 2
  #read_scale     = false
  sku_name       = "S0"
 # zone_redundant = true
  enclave_type   = "VBS"
 
}


#### Define Azure Load Balancer and backend pool for WebApp####
#Create PIP Loadbalancer
resource "azurerm_public_ip" "lb-public-ip" {
  name                = "web-lb-public-ip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  allocation_method   = "Static"
}
#Create Load Balancer
resource "azurerm_lb" "web_lb" {
  name                = "web_lb"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddressLB"
    public_ip_address_id = azurerm_public_ip.lb-public-ip.id
  }
}
resource "azurerm_network_interface" "web_lb_nic" {
  name                = "web_lb_nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.webappsubnet.id
    private_ip_address_allocation = "Dynamic"
  }
}
# Create LB Backend Pool
resource "azurerm_lb_backend_address_pool" "web_lb_backend_address_pool" {
  name                = "web-backend"
  loadbalancer_id     = azurerm_lb.web_lb.id
}

# Resource-6: Associate Network Interface and Standard Load Balancer
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_backend_address_pool_association
resource "azurerm_network_interface_backend_address_pool_association" "webapp_nic_lb_associate" {
  network_interface_id    = azurerm_network_interface.nic_vm_webapp.id
  ip_configuration_name   = azurerm_network_interface.nic_vm_webapp.ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.web_lb_backend_address_pool.id
}
resource "azurerm_network_interface_backend_address_pool_association" "webapp2_nic_lb_associate" {
  network_interface_id    = azurerm_network_interface.nic_vm_webapp2.id
  ip_configuration_name   = azurerm_network_interface.nic_vm_webapp2.ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.web_lb_backend_address_pool.id
}

#### Define Azure DNS Zone and Records ####
# Create an Azure DNS zone
resource "azurerm_dns_zone" "dnszone" {
  name                = "testwebapp.com"
  resource_group_name = azurerm_resource_group.rg.name
}
# Create a DNS record set pointing to an IP address (e.g., a resource within the VNET)
resource "azurerm_dns_a_record" "webapp-dns-record" {
  name                = "webapp-dns-record"
  zone_name           = azurerm_dns_zone.dnszone.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 300
  records             = ["20.70.75.49"]
}



# Define a private link and endpoint within the Virtual Network

#Create LoadBalancer 
resource "azurerm_public_ip" "endpoint_lb_pip" {
  name                = "enpoint_lb_pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  allocation_method   = "Static"
}
resource "azurerm_lb" "enpoint_lb" {
  name                = "endpoint-lb"
  sku                 = "Standard"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  frontend_ip_configuration {
    name                 = azurerm_public_ip.endpoint_lb_pip.name
    public_ip_address_id = azurerm_public_ip.endpoint_lb_pip.id
  }
}

resource "azurerm_private_link_service" "privatelink" {
  name                = "privatelink"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
 # auto_approval_subscription_ids              = ["dc3f097d-41a3-4f48-bcf6-7957cf874a41"]
 # visibility_subscription_ids                 = ["dc3f097d-41a3-4f48-bcf6-7957cf874a41"]
  load_balancer_frontend_ip_configuration_ids = [azurerm_lb.enpoint_lb.frontend_ip_configuration.0.id]
  

  nat_ip_configuration {
    name      = azurerm_public_ip.endpoint_lb_pip.name
    # name                       = "primary"
    # private_ip_address         = "10.0.2.17"
    # private_ip_address_version = "IPv4"
    subnet_id                  = azurerm_subnet.databasesubnet.id
    primary                    = true
  }
}

resource "azurerm_private_endpoint" "sqlendpoint" {
  name                = "sql-private-endpoint"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.databasesubnet.id
  
  private_service_connection {
    name                           = "private-connection"
    private_connection_resource_id = azurerm_mssql_server.sqlprivateserver.id
    subresource_names              = [ "sqlServer" ]
    is_manual_connection           = false
    #is_connection_monitor_enabled  = false

  }
}


####  Create a On-prem (simulated) virtual network ####
resource "azurerm_virtual_network" "onpremvnet" {
  name          = "onpremvnet"
  address_space = ["10.1.0.0/16"]

  location            = "australiasoutheast"
  resource_group_name = azurerm_resource_group.rg.name
}
resource "azurerm_subnet" "vpngateway_onprem_subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.onpremvnet.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_virtual_network_gateway" "onprem_vpngateway" {
  name                = "onpremvnet_vpn_gateway"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "Basic"
  active_active       = false
  enable_bgp          = false
  ip_configuration {
    name                          = "onpremGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.onprem_pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.vpngateway_onprem_subnet.id
  }
}

resource "azurerm_public_ip" "onprem_pip" {
  name                = "onprem_gatewaypip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  allocation_method = "Dynamic"
}

#Create Vnet-to-Vnet connection
resource "azurerm_virtual_network_gateway_connection" "azure_to_onprem" {
  name                = "azure_to_onprem"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.vpngateway.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.onprem_vpngateway.id

  shared_key = "4-v3ry-53cr37-1p53c-5h4r3d-k3y"
}

resource "azurerm_virtual_network_gateway_connection" "onprem_to_azure" {
  name                = "onprem_to_azure"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.onprem_vpngateway.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.vpngateway.id

  shared_key = "4-v3ry-53cr37-1p53c-5h4r3d-k3y"
}


#Create a Local Network for On-prem site-to-site connection

resource "azurerm_local_network_gateway" "onpremise" {
  name                = "onpremise"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  gateway_address     = "168.62.225.23"
  address_space       = ["10.2.0.0/24"]
}

#Create Site-to-Site connection

resource "azurerm_virtual_network_gateway_connection" "onpremise" {
  name                = "onpremise"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpngateway.id
  local_network_gateway_id   = azurerm_local_network_gateway.onpremise.id

  shared_key = "4-v3ry-53cr37-1p53c-5h4r3d-k3y"
}