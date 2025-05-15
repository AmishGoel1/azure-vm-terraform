resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "random_pet" "rg_name_vm2" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = random_pet.rg_name.id
}

resource "azurerm_resource_group" "rg_vm2" {
  location = var.resource_group_location
  name = random_pet.rg_name_vm2.id
}

# Create virtual network
resource "azurerm_virtual_network" "my_terraform_network" {
  name                = "myVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_virtual_network" "vnet2_vm2" {

  name = "myVnet2"
  address_space = ["10.1.0.0/16"]
  location = azurerm_resource_group.rg_vm2.location
  resource_group_name = azurerm_resource_group.rg_vm2.name
  
}

# Create subnet
resource "azurerm_subnet" "my_terraform_subnet" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.my_terraform_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "subnet_vm2" {
  name = "mySubnet"
  resource_group_name = azurerm_resource_group.rg_vm2.name
  virtual_network_name = azurerm_virtual_network.vnet2_vm2.name
  address_prefixes = ["10.1.1.0/24"]
  
}

# Create public IPs
resource "azurerm_public_ip" "my_terraform_public_ip" {
  name                = "myPublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "public_ip_vm2" {
  name = "myPublicIP"
  location = azurerm_resource_group.rg_vm2.location
  resource_group_name = azurerm_resource_group.rg_vm2.name
  allocation_method = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "my_terraform_nsg" {
  name                = "myNetworkSecurityGroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "nsg_vm2" {
  name = "NSGVm2"
  location = azurerm_resource_group.rg_vm2.location
  resource_group_name = azurerm_resource_group.rg_vm2.name
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }  
}

# Create network interface
resource "azurerm_network_interface" "my_terraform_nic" {
  name                = "myNIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.my_terraform_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.my_terraform_public_ip.id
  }
}

resource "azurerm_network_interface" "nic_vm2" {
  name                = "nicVM2"
  location            = azurerm_resource_group.rg_vm2.location
  resource_group_name = azurerm_resource_group.rg_vm2.name

  ip_configuration {
    name = "nic_configuration_vm2"
    subnet_id = azurerm_subnet.subnet_vm2.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.public_ip_vm2.id
  }
}


# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.my_terraform_nic.id
  network_security_group_id = azurerm_network_security_group.my_terraform_nsg.id
}

resource "azurerm_network_interface_security_group_association" "example_vm2" {
  network_interface_id = azurerm_network_interface.nic_vm2.id
  network_security_group_id = azurerm_network_security_group.nsg_vm2.id
}

# Generate random text for a unique storage account name
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg.name
  }

  byte_length = 8
}

resource "random_id" "random_id_2" {
  keepers = {
    resource_group = azurerm_resource_group.rg_vm2.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "my_storage_account" {
  name                     = "diag${random_id.random_id.hex}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_account" "storage_account_vm2" {
  name = "diag${random_id.random_id_2.hex}"
  location = azurerm_resource_group.rg_vm2.location
  resource_group_name = azurerm_resource_group.rg_vm2.name
  account_tier = "Standard"
  account_replication_type = "LRS"
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "my_terraform_vm" {
  name                  = "myVM"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.my_terraform_nic.id]
  size                  = "Standard_B1s"

  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb = "64"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name  = "hostname"
  admin_username = var.username

  admin_ssh_key {
    username   = var.username
    public_key = azapi_resource_action.ssh_public_key_gen.output.publicKey
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.my_storage_account.primary_blob_endpoint
  }
}

resource "azurerm_linux_virtual_machine" "Vm2" {
  name                  = "myVM"
  location              = azurerm_resource_group.rg_vm2.location
  resource_group_name   = azurerm_resource_group.rg_vm2.name
  network_interface_ids = [azurerm_network_interface.nic_vm2.id]
  size                  = "Standard_B1s"

  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb = "64"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name  = "hostname"
  admin_username = var.username

  admin_ssh_key {
    username   = var.username
    public_key = azapi_resource_action.ssh_public_key_gen_vm2.output.publicKey
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.storage_account_vm2.primary_blob_endpoint
  }
}
resource "azurerm_virtual_network_peering" "peer-1" {
  name                      = "peer1to2"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.my_terraform_network.name
  remote_virtual_network_id = azurerm_virtual_network.vnet2_vm2.id
}

resource "azurerm_virtual_network_peering" "peer-2" {
  name                      = "peer2to1"
  resource_group_name       = azurerm_resource_group.rg_vm2.name
  virtual_network_name      = azurerm_virtual_network.vnet2_vm2.name
  remote_virtual_network_id = azurerm_virtual_network.my_terraform_network.id
}