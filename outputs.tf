output "indexer_ssh_connection" {
  description = "Command to connect to the Indexer"
  value       = "ssh -i ./id_rsa azureuser@${azurerm_public_ip.indexer_ip.ip_address}"
}

output "forwarder_ssh_connection" {
  description = "Command to connect to the Forwarder"
  value       = "ssh -i ./id_rsa azureuser@${azurerm_public_ip.forwarder_ip.ip_address}"
}