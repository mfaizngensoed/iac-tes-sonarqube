# ====================================================================
# VPC - Virtual Private Cloud
# ====================================================================
resource "digitalocean_vpc" "simut_vpc" {
  name     = var.vpc_name
  region   = var.region
  ip_range = var.vpc_cidr

  description = "Private network for SIMUT infrastructure"
}

# ====================================================================
# SSH Key Data Source
# ====================================================================
data "digitalocean_ssh_key" "key_terraform" {
  name = var.ssh_key_name
}

# ====================================================================
# Cloud-init User Data Scripts
# ====================================================================

# User data for Service Node (Droplet 1) - Bun + Docker
locals {
  service_node_user_data = <<-EOF
    #!/bin/bash
    set -e
    
    # Log everything
    exec > >(tee /var/log/user-data.log)
    exec 2>&1
    
    echo "=== Starting Service Node Setup ==="
    date
    
    # Create user simut FIRST (before any package installation)
    echo "Creating user simut..."
    useradd -m -s /bin/bash simut || true
    echo "simut:simut123" | chpasswd
    usermod -aG sudo simut
    
    # Setup directories
    mkdir -p /opt/services/{api-gateway,testimonial,gad7,journal,statistics}
    
    # Update system (non-interactive, without upgrade to avoid SSH restart)
    echo "Updating package lists..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    
    # Install Docker
    echo "Installing Docker..."
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    systemctl enable docker
    systemctl start docker
    
    # Add users to docker group
    usermod -aG docker root
    usermod -aG docker simut
    
    # Install Bun (as simut user)
    echo "Installing Bun..."
    su - simut -c 'curl -fsSL https://bun.sh/install | bash'
    
    # Setup UFW Firewall
    echo "Configuring UFW..."
    ufw --force enable
    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw allow from 10.10.0.0/16
    
    # Set permissions
    chown -R simut:simut /opt/services
    
    # Mark completion
    echo "=== Service Node Setup Completed ===" 
    date
    echo "setup_completed" > /var/log/cloud-init-done.log
    
    # Optional: System upgrade in background (won't interrupt SSH)
    nohup apt-get upgrade -y &
  EOF

  # User data for ML Node (Droplet 2) - Python + FastAPI + Docker
  ml_node_user_data = <<-EOF
    #!/bin/bash
    set -e
    
    # Log everything
    exec > >(tee /var/log/user-data.log)
    exec 2>&1
    
    echo "=== Starting ML Node Setup ==="
    date
    
    # Create user simut FIRST
    echo "Creating user simut..."
    useradd -m -s /bin/bash simut || true
    echo "simut:simut123" | chpasswd
    usermod -aG sudo simut
    
    # Setup directories
    mkdir -p /opt/ml-models/{gad7-model,journal-model}
    
    # Update system (non-interactive, without upgrade to avoid SSH restart)
    echo "Updating package lists..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    
    # Install Docker
    echo "Installing Docker..."
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    systemctl enable docker
    systemctl start docker
    
    # Add users to docker group
    usermod -aG docker root
    usermod -aG docker simut
    
    # Install Python and pip
    echo "Installing Python and ML libraries..."
    apt-get install -y python3 python3-pip python3-venv
    pip3 install --upgrade pip --break-system-packages || pip3 install --upgrade pip
    pip3 install fastapi uvicorn[standard] --break-system-packages || pip3 install fastapi uvicorn[standard]
    
    # Setup UFW Firewall
    echo "Configuring UFW..."
    ufw --force enable
    ufw allow 22/tcp
    ufw allow from 10.10.0.0/16
    
    # Set permissions
    chown -R simut:simut /opt/ml-models
    
    # Mark completion
    echo "=== ML Node Setup Completed ==="
    date
    echo "setup_completed" > /var/log/cloud-init-done.log
    
    # Optional: System upgrade and additional ML libraries in background
    nohup bash -c 'apt-get upgrade -y && pip3 install numpy pandas scikit-learn --break-system-packages' &
  EOF
}

# ====================================================================
# Droplet 1: Service Node (Public Facing)
# ====================================================================
resource "digitalocean_droplet" "service_node" {
  image    = var.droplet_image
  name     = "service-node"
  region   = var.region
  size     = var.droplet_size
  vpc_uuid = digitalocean_vpc.simut_vpc.id

  ssh_keys = [
    data.digitalocean_ssh_key.key_terraform.id
  ]

  user_data = local.service_node_user_data

  tags = ["service-node", "public-facing"]

  # Enable monitoring
  monitoring = true
}

# ====================================================================
# Droplet 2: ML Node (Private Only)
# ====================================================================
resource "digitalocean_droplet" "ml_node" {
  image    = var.droplet_image
  name     = "ml-node"
  region   = var.region
  size     = var.droplet_size
  vpc_uuid = digitalocean_vpc.simut_vpc.id

  ssh_keys = [
    data.digitalocean_ssh_key.key_terraform.id
  ]

  user_data = local.ml_node_user_data

  tags = ["ml-node", "private"]

  # Enable monitoring
  monitoring = true
}

# ====================================================================
# PostgreSQL Managed Database
# ====================================================================
resource "digitalocean_database_cluster" "postgres" {
  name       = "simut-postgres"
  engine     = "pg"
  version    = var.db_engine_version
  size       = var.db_size
  region     = var.region
  node_count = 1

  private_network_uuid = digitalocean_vpc.simut_vpc.id

  tags = ["database", "postgres"]
}

# Create database user
resource "digitalocean_database_user" "simut_user" {
  cluster_id = digitalocean_database_cluster.postgres.id
  name       = var.db_user
}

# Create database
resource "digitalocean_database_db" "simut_database" {
  cluster_id = digitalocean_database_cluster.postgres.id
  name       = var.db_name
}

# Database Firewall - Allow only from Service Node and ML Node via private network
resource "digitalocean_database_firewall" "postgres_firewall" {
  cluster_id = digitalocean_database_cluster.postgres.id

  # Allow from Service Node
  rule {
    type  = "droplet"
    value = digitalocean_droplet.service_node.id
  }

  # Allow from ML Node
  rule {
    type  = "droplet"
    value = digitalocean_droplet.ml_node.id
  }
}

# ====================================================================
# Cloud Firewall for Service Node (Public Facing)
# ====================================================================
resource "digitalocean_firewall" "service_node_firewall" {
  name = "service-node-firewall"

  droplet_ids = [digitalocean_droplet.service_node.id]

  # Inbound Rules
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Allow all traffic from VPC (for internal communication)
  inbound_rule {
    protocol         = "tcp"
    port_range       = "1-65535"
    source_addresses = [var.vpc_cidr]
  }

  inbound_rule {
    protocol         = "udp"
    port_range       = "1-65535"
    source_addresses = [var.vpc_cidr]
  }

  # Outbound Rules - Allow all
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

# ====================================================================
# Cloud Firewall for ML Node (Private Only)
# ====================================================================
resource "digitalocean_firewall" "ml_node_firewall" {
  name = "ml-node-firewall"

  droplet_ids = [digitalocean_droplet.ml_node.id]

  # Inbound Rules
  # SSH from management IP (your IP or anywhere for now)
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = [var.management_ip]
  }

  # Allow all traffic from Service Node via VPC
  inbound_rule {
    protocol         = "tcp"
    port_range       = "1-65535"
    source_addresses = [var.vpc_cidr]
  }

  inbound_rule {
    protocol         = "udp"
    port_range       = "1-65535"
    source_addresses = [var.vpc_cidr]
  }

  inbound_rule {
    protocol         = "icmp"
    source_addresses = [var.vpc_cidr]
  }

  # Outbound Rules - Allow all (for package updates)
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}
