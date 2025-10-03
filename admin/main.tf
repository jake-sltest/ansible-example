provider "azurerm" {
  features {}
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
  subnet_id      = var.subnet_id
  worker_pool_id = var.worker_pool_id
}
