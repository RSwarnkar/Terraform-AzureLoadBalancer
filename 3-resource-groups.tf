
resource "azurerm_resource_group" "rg01" {
  name     = var.rg01.name
  location = var.rg01.location
  tags     = var.default_tags
  provider = azurerm
}
