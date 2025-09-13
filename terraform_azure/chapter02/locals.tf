# Locals for naming, networking, and tagging
locals {
  base_name = "chapter02"
  location  = "westeurope"

  rg_name   = "${local.base_name}-rg"
  vnet_name = "${local.base_name}-vnet"
  subnet    = "${local.base_name}-subnet"
  nsg_name  = "${local.base_name}-nsg"
  pip_name  = "${local.base_name}-pip"
  nic_name  = "${local.base_name}-nic"
  vm_name   = "${local.base_name}-vm"

  # Networking locals
  vnet_cidr   = ["10.0.0.0/16"]
  subnet_cidr = ["10.0.2.0/24"]

  # Tags
  tags = {
    source = "terraform"
    env    = "lab"
  }
}