resource "random_pet" "ssh_key_name" {
  prefix    = "ssh"
  separator = ""
}

resource "random_pet" "ssh_key_name_vm2" {
  prefix = "ssh"
  separator = ""
}

resource "azapi_resource_action" "ssh_public_key_gen" {
  type        = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  resource_id = azapi_resource.ssh_public_key.id
  action      = "generateKeyPair"
  method      = "POST"

  response_export_values = ["publicKey", "privateKey"]
}

resource "azapi_resource_action" "ssh_public_key_gen_vm2" {
  type        = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  resource_id = azapi_resource.ssh_publick_key_vm2.id
  action      = "generateKeyPair"
  method      = "POST"

  response_export_values = ["publicKey", "privateKey"]

}

resource "azapi_resource" "ssh_public_key" {
  type      = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  name      = random_pet.ssh_key_name.id
  location  = azurerm_resource_group.rg.location
  parent_id = azurerm_resource_group.rg.id
}

resource "azapi_resource" "ssh_publick_key_vm2" {
  type = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  name = random_pet.ssh_key_name_vm2.id
  location = azurerm_resource_group.rg.location
  parent_id = azurerm_resource_group.rg_vm2.id
}

output "key_data_vm2" {
  value = azapi_resource_action.ssh_public_key_gen_vm2.output.publicKey
}

output "key_data_vm2_private" {
  value = azapi_resource_action.ssh_public_key_gen_vm2.output.privateKey
}

output "key_data" {
  value = azapi_resource_action.ssh_public_key_gen.output.publicKey
}

output "private_key_data" {
  value = azapi_resource_action.ssh_public_key_gen.output.privateKey
}