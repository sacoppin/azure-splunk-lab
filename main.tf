# main.tf

# 1. IMPORT EXISTING RESOURCE GROUP
# We use a "data" source to read the properties of your existing RG
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# 2. NETWORK ARCHITECTURE (VNet & Subnet)
resource "azurerm_virtual_network" "vnet" {
  name                = "splunk-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "internal-subnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# 3. SECURITY (Network Security Group - NSG)
resource "azurerm_network_security_group" "nsg" {
  name                = "splunk-nsg"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  # SSH Access - Restricted to Admin IP (Your IP)
  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.admin_public_ip
    destination_address_prefix = "*"
  }

  # Splunk Web UI (Port 8000)
  security_rule {
    name                       = "AllowSplunkWeb"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Splunk Ingestion (Port 9997) - Internal Traffic Only
  security_rule {
    name                       = "AllowSplunkIngestion"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9997"
    source_address_prefix      = "10.0.0.0/16" # Only allow traffic from inside the VNet
    destination_address_prefix = "*"
  }
}

# 4. PUBLIC IPs (FIXED: Using Standard SKU)
resource "azurerm_public_ip" "indexer_ip" {
  name                = "pip-indexer"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"   # Required for Standard SKU
  sku                 = "Standard" # Fixed: Basic SKU is deprecated
}

resource "azurerm_public_ip" "forwarder_ip" {
  name                = "pip-forwarder"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"   # Required for Standard SKU
  sku                 = "Standard" # Fixed: Basic SKU is deprecated
}

# 5. NETWORK INTERFACES (NICs)
# Indexer NIC
resource "azurerm_network_interface" "indexer_nic" {
  name                = "nic-indexer"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.indexer_ip.id
  }
}

# Attach NSG to Indexer
resource "azurerm_network_interface_security_group_association" "indexer_assoc" {
  network_interface_id      = azurerm_network_interface.indexer_nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Forwarder NIC
resource "azurerm_network_interface" "forwarder_nic" {
  name                = "nic-forwarder"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.forwarder_ip.id
  }
}

# Attach NSG to Forwarder
resource "azurerm_network_interface_security_group_association" "forwarder_assoc" {
  network_interface_id      = azurerm_network_interface.forwarder_nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# 6. VIRTUAL MACHINES
# VM 1: Splunk Indexer (High Memory - Standard_B2s)
resource "azurerm_linux_virtual_machine" "indexer" {
  name                = "vm-splunk-indexer"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  size                = "Standard_B2s"
  admin_username      = "azureuser"
  network_interface_ids = [azurerm_network_interface.indexer_nic.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("./id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

# VM 2: Universal Forwarder (Lightweight - Standard_B1s)
resource "azurerm_linux_virtual_machine" "forwarder" {
  name                = "vm-splunk-forwarder"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  network_interface_ids = [azurerm_network_interface.forwarder_nic.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("./id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}