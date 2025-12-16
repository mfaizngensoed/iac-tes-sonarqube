# ====================================================================
# VPC Outputs
# ====================================================================
output "vpc_id" {
  description = "ID of the VPC"
  value       = digitalocean_vpc.simut_vpc.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = digitalocean_vpc.simut_vpc.ip_range
}

# ====================================================================
# Service Node Outputs (Droplet 1)
# ====================================================================
output "service_node_id" {
  description = "ID of the Service Node droplet"
  value       = digitalocean_droplet.service_node.id
}

output "service_node_name" {
  description = "Name of the Service Node droplet"
  value       = digitalocean_droplet.service_node.name
}

output "service_node_public_ip" {
  description = "Public IPv4 address of Service Node"
  value       = digitalocean_droplet.service_node.ipv4_address
}

output "service_node_private_ip" {
  description = "Private IPv4 address of Service Node"
  value       = digitalocean_droplet.service_node.ipv4_address_private
}

output "service_node_ssh_command" {
  description = "SSH command to connect to Service Node"
  value       = "ssh root@${digitalocean_droplet.service_node.ipv4_address}"
}

# ====================================================================
# ML Node Outputs (Droplet 2)
# ====================================================================
output "ml_node_id" {
  description = "ID of the ML Node droplet"
  value       = digitalocean_droplet.ml_node.id
}

output "ml_node_name" {
  description = "Name of the ML Node droplet"
  value       = digitalocean_droplet.ml_node.name
}

output "ml_node_public_ip" {
  description = "Public IPv4 address of ML Node"
  value       = digitalocean_droplet.ml_node.ipv4_address
}

output "ml_node_private_ip" {
  description = "Private IPv4 address of ML Node"
  value       = digitalocean_droplet.ml_node.ipv4_address_private
}

output "ml_node_ssh_command" {
  description = "SSH command to connect to ML Node"
  value       = "ssh root@${digitalocean_droplet.ml_node.ipv4_address}"
}

# ====================================================================
# PostgreSQL Database Outputs
# ====================================================================
output "postgres_id" {
  description = "ID of the PostgreSQL cluster"
  value       = digitalocean_database_cluster.postgres.id
}

output "postgres_host" {
  description = "PostgreSQL host (public)"
  value       = digitalocean_database_cluster.postgres.host
}

output "postgres_private_host" {
  description = "PostgreSQL private host (use this from droplets)"
  value       = digitalocean_database_cluster.postgres.private_host
}

output "postgres_port" {
  description = "PostgreSQL port"
  value       = digitalocean_database_cluster.postgres.port
}

output "postgres_database" {
  description = "PostgreSQL database name"
  value       = digitalocean_database_db.simut_database.name
}

output "postgres_user" {
  description = "PostgreSQL username"
  value       = digitalocean_database_user.simut_user.name
}

output "postgres_password" {
  description = "PostgreSQL password (sensitive)"
  value       = digitalocean_database_user.simut_user.password
  sensitive   = true
}

output "postgres_uri" {
  description = "PostgreSQL connection URI (private network)"
  value       = digitalocean_database_cluster.postgres.private_uri
  sensitive   = true
}

# ====================================================================
# Connection Information Summary
# ====================================================================
output "connection_info" {
  description = "Summary of connection information"
  value = {
    service_node = {
      public_ip  = digitalocean_droplet.service_node.ipv4_address
      private_ip = digitalocean_droplet.service_node.ipv4_address_private
      ssh        = "ssh root@${digitalocean_droplet.service_node.ipv4_address}"
      user_access = "ssh simut@${digitalocean_droplet.service_node.ipv4_address} (password: simut123)"
    }
    ml_node = {
      public_ip  = digitalocean_droplet.ml_node.ipv4_address
      private_ip = digitalocean_droplet.ml_node.ipv4_address_private
      ssh        = "ssh root@${digitalocean_droplet.ml_node.ipv4_address}"
      user_access = "ssh simut@${digitalocean_droplet.ml_node.ipv4_address} (password: simut123)"
    }
    database = {
      host         = digitalocean_database_cluster.postgres.private_host
      port         = digitalocean_database_cluster.postgres.port
      database     = digitalocean_database_db.simut_database.name
      user         = digitalocean_database_user.simut_user.name
      access_info  = "Username: simut, Password: [use terraform output postgres_password to view]"
    }
  }
}

# ====================================================================
# Quick Start Guide
# ====================================================================
output "quick_start" {
  description = "Quick start commands and information"
  value = <<-EOT
    
    🚀 SIMUT Infrastructure Deployed Successfully!
    
    📦 Service Node (Public Facing):
       Public IP:  ${digitalocean_droplet.service_node.ipv4_address}
       Private IP: ${digitalocean_droplet.service_node.ipv4_address_private}
       SSH (root): ssh root@${digitalocean_droplet.service_node.ipv4_address}
       SSH (user): ssh simut@${digitalocean_droplet.service_node.ipv4_address}
       
    🤖 ML Node (Private):
       Public IP:  ${digitalocean_droplet.ml_node.ipv4_address}
       Private IP: ${digitalocean_droplet.ml_node.ipv4_address_private}
       SSH (root): ssh root@${digitalocean_droplet.ml_node.ipv4_address}
       SSH (user): ssh simut@${digitalocean_droplet.ml_node.ipv4_address}
       
    🗄️  PostgreSQL Database:
       Host (private): ${digitalocean_database_cluster.postgres.private_host}
       Port: ${digitalocean_database_cluster.postgres.port}
       Database: ${digitalocean_database_db.simut_database.name}
       Username: simut
       Password: Run 'terraform output postgres_password' to view
       
    🔐 User Credentials (all servers):
       Username: simut
       Password: simut123
       
    📝 Next Steps:
       1. SSH into servers using the commands above
       2. Deploy your Docker containers
       3. Configure services to use private network IPs
       4. Use postgres_private_host for database connections
       
    💡 Tips:
       - All services can communicate via private network (10.10.0.0/16)
       - Service Node exposes ports 22, 80, 443 to the internet
       - ML Node only accepts SSH from your IP and traffic from VPC
       - Database only accepts connections from the two droplets
    
  EOT
}
