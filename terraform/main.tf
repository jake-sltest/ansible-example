provider "azurerm" {
  features {}
}

resource "azurerm_network_interface" "vm_nic" {
  name                = "nic-winrm-demo"
  location            = "eastus"
  resource_group_name = "rg-winrm-demo"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = "/subscriptions/d2d840cc-eb24-4500-a29f-6cddefb542a4/resourceGroups/rg-winrm-demo/providers/Microsoft.Network/virtualNetworks/vnet-winrm-demo/subnets/subnet-winrm-demo"
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                  = "vm-winrm-demo"
  location              = "eastus"
  resource_group_name   = "rg-winrm-demo"
  network_interface_ids = [azurerm_network_interface.vm_nic.id]
  size                  = "Standard_B2ms"

  admin_username = "azureuser"
  admin_password = "YourP@ssword123!" # Replace with secure password

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  # Optional: Enable WinRM over HTTPS
  # winrm {
  #   protocol = "https"
  # }
}

output "vm_private_ip" {
  value = azurerm_network_interface.vm_nic.private_ip_address
}
