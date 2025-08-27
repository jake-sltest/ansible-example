provider "azurerm" {
  features {}
}

#############################
# Resource Group
#############################
resource "azurerm_resource_group" "rg" {
  name     = "rg-winrm-demo"
  location = "East US"
}

#############################
# Virtual Network & Subnet
#############################
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-winrm-demo"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-winrm-demo"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

#############################
# Network Security Group
#############################
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-winrm-demo"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Allow WinRM HTTP (5985)
resource "azurerm_network_security_rule" "winrm_http" {
  name                        = "Allow-WinRM-HTTP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5985"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# Optional: allow RDP (3389) for admin
resource "azurerm_network_security_rule" "rdp" {
  name                        = "Allow-RDP"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

#############################
# Public IP & NIC
#############################
resource "azurerm_public_ip" "vm_public_ip" {
  name                = "vm-winrm-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nic" {
  name                = "nic-winrm-demo"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_public_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nic_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

#############################
# Windows VM
#############################
resource "azurerm_windows_virtual_machine" "vm" {
  name                  = "vm-winrm-demo"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = "Standard_B2ms"
  admin_username        = "azureuser"
  admin_password        = "P@ssw0rd1234!"
  network_interface_ids = [azurerm_network_interface.nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

#############################
# Configure WinRM over HTTP
#############################
resource "azurerm_virtual_machine_extension" "winrm_http" {
  name                 = "enable-winrm-http"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    commandToExecute = <<EOT
powershell -ExecutionPolicy Unrestricted -Command "
# Ensure WinRM service is running
Set-Service WinRM -StartupType Automatic
Start-Service WinRM

# Configure service for HTTP + NTLM
winrm quickconfig -q
winrm set winrm/config/service @{AllowUnencrypted='true'}
winrm set winrm/config/service/auth @{Basic='true';CredSSP='true';NTLM='true'}

# Firewall rule for HTTP
if (-not (Get-NetFirewallRule -DisplayName 'Allow WinRM HTTP' -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName 'Allow WinRM HTTP' -Direction Inbound -Protocol TCP -LocalPort 5985 -Action Allow
}
"
EOT
  })
}

#############################
# Terraform Output for Ansible
#############################
output "winvm_private_ip" {
  value = azurerm_network_interface.nic.private_ip_address
}

output "ansible_inventory" {
  value = <<EOT
[windows]
winvm ansible_host=${azurerm_network_interface.nic.private_ip_address} ansible_user=azureuser ansible_password=P@ssw0rd1234! ansible_port=5985 ansible_connection=winrm ansible_winrm_transport=ntlm ansible_winrm_server_cert_validation=ignore
EOT
}
