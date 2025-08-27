terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.61.0"
    }
  }
}

data "azurerm_resource_group" "rg-winrm-demo" {
  name = "rg-winrm-demo"
}

module "azure-worker" {
  source = "github.com/spacelift-io/terraform-azure-spacelift-workerpool?ref=v1.0.0"

  admin_password = "Super Secret Password!"

  configuration = <<-EOT
    export SPACELIFT_TOKEN="${var.worker_pool_config}"
    export SPACELIFT_POOL_PRIVATE_KEY="${var.worker_pool_private_key}"
  EOT

  resource_group = data.azurerm_resource_group.rg-winrm-demo # An azurerm_resource_group object - must have `name` and `location` properties
  subnet_id      = "/subscriptions/d2d840cc-eb24-4500-a29f-6cddefb542a4/resourceGroups/rg-winrm-demo/providers/Microsoft.Network/virtualNetworks/vnet-winrm-demo/subnets/subnet-winrm-demo"
  worker_pool_id = "01K3PDK560Q2R75KGZN22C4C7Z"
}
