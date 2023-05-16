output "master_node_dns" {
  value = module.master_node.public_dns
}

output "master_node_public_ip" {
  value = module.master_node.public_ip
}

output "target_node_dns" {
  value = module.target_nodes[*].public_dns
}

output "target_node_public_ip" {
  value = module.target_nodes[*].public_ip
}


