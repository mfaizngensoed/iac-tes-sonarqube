# SIMUT Infrastructure - DigitalOcean Terraform

Infrastruktur lengkap untuk SIMUT menggunakan Terraform di DigitalOcean.

## 🏗️ Arsitektur

### Network
- **VPC**: Private network (10.10.0.0/16) untuk komunikasi internal antar resource
- Region: Singapore (sgp1)

### Compute
1. **Service Node** (Public Facing)
   - Ubuntu 24.04, 1 CPU, 1 GB RAM
   - Docker + Bun pre-installed
   - Services: API Gateway, Testimonial, GAD-7, Journal, Statistics
   - Ports: 22 (SSH), 80 (HTTP), 443 (HTTPS)
   - User: simut / simut123

2. **ML Node** (Private)
   - Ubuntu 24.04, 1 CPU, 1 GB RAM
   - Docker + Python + FastAPI pre-installed
   - Services: GAD-7 Model, Journal Model
   - Private only, SSH dari management IP
   - User: simut / simut123

### Database
- **PostgreSQL 16** Managed Database
- 1 CPU, 1 GB RAM
- Private network only
- Database: simut_db
- User: simut / simut123
- Hanya bisa diakses dari Service Node dan ML Node

### Security
- Cloud Firewall untuk Service Node (public access)
- Cloud Firewall untuk ML Node (private only)
- Database Firewall (whitelist droplets only)
- UFW firewall di setiap droplet

## 📋 Prerequisites

1. **DigitalOcean Account** dengan API Token
2. **SSH Key** sudah di-upload ke DigitalOcean dengan nama `key-terraform`
3. **Terraform** installed (v1.0+)

## 🚀 Quick Start

### 1. Clone/Setup
```bash
cd /home/vrs/Kuliah/iac-digitalOcean
```

### 2. Review Configuration
Edit `terraform.tfvars` sesuai kebutuhan:
```bash
nano terraform.tfvars
```

**PENTING**: Ubah `management_ip` dengan IP publik Anda untuk keamanan:
```bash
# Dapatkan IP publik Anda
curl ifconfig.me

# Edit terraform.tfvars
management_ip = "YOUR_PUBLIC_IP/32"
```

### 3. Initialize Terraform
```bash
terraform init
```

### 4. Review Plan
```bash
terraform plan
```

### 5. Deploy Infrastructure
```bash
terraform apply
```

Ketik `yes` untuk konfirmasi.

### 6. Get Outputs
```bash
# Lihat semua output
terraform output

# Quick start guide
terraform output quick_start

# Database password (sensitive)
terraform output postgres_password
```

## 📁 File Structure

```
.
├── provider.tf          # Provider configuration
├── variables.tf         # Variable definitions
├── terraform.tfvars     # Variable values (SENSITIVE)
├── main.tf             # Main infrastructure code
├── outputs.tf          # Output definitions
├── README.md           # This file
└── backup/             # Backup of old files
```

## 🔐 Access Information

### Service Node (Public)
```bash
# SSH as root
ssh root@<service_node_public_ip>

# SSH as simut user
ssh simut@<service_node_public_ip>
# Password: simut123
```

### ML Node (Private)
```bash
# SSH as root
ssh root@<ml_node_public_ip>

# SSH as simut user
ssh simut@<ml_node_public_ip>
# Password: simut123
```

### PostgreSQL Database
```bash
# Connection from droplets (use private host)
Host: <postgres_private_host>
Port: 25060
Database: simut_db
Username: simut
Password: [run terraform output postgres_password]

# Connection string example
postgresql://simut:PASSWORD@<private_host>:25060/simut_db?sslmode=require
```

## 🐳 Docker Setup

Kedua droplet sudah ter-install Docker. User `simut` sudah masuk docker group.

### Service Node - Deploy Services
```bash
# Login ke Service Node
ssh simut@<service_node_ip>

# Example: Run API Gateway container
cd /opt/services/api-gateway
docker run -d -p 80:3000 --name api-gateway your-image:tag

# Check running containers
docker ps
```

### ML Node - Deploy ML Models
```bash
# Login ke ML Node
ssh simut@<ml_node_ip>

# Example: Run GAD-7 Model container
cd /opt/ml-models/gad7-model
docker run -d -p 8000:8000 --name gad7-model your-ml-image:tag

# Check running containers
docker ps
```

## 🌐 Private Network Communication

Semua resource bisa berkomunikasi menggunakan **private IP**:

```bash
# Dari Service Node, akses ML Node
curl http://<ml_node_private_ip>:8000/predict

# Dari Service Node, akses Database
psql postgresql://simut:PASSWORD@<postgres_private_host>:25060/simut_db
```

## 🔧 Maintenance Commands

### View Infrastructure State
```bash
terraform show
```

### Update Infrastructure
```bash
# Edit main.tf atau variables.tf
terraform plan
terraform apply
```

### Destroy Infrastructure
```bash
terraform destroy
```

**WARNING**: Ini akan menghapus semua resource!

### Check Cloud-init Status
```bash
# SSH ke droplet
ssh root@<droplet_ip>

# Check cloud-init log
tail -f /var/log/cloud-init-output.log

# Check if setup completed
cat /var/log/cloud-init-done.log
```

## 📊 Monitoring

Monitoring sudah enabled untuk semua droplets. Akses via:
- DigitalOcean Dashboard → Monitoring
- Metrics: CPU, Memory, Disk, Network

## 🔒 Security Best Practices

1. **Change management_ip** dari 0.0.0.0/0 ke IP spesifik Anda
2. **Rotate passwords** setelah deployment:
   ```bash
   ssh simut@<droplet_ip>
   passwd
   ```
3. **Setup SSH key auth** dan disable password:
   ```bash
   # Copy your SSH public key
   ssh-copy-id simut@<droplet_ip>
   
   # Disable password auth
   sudo nano /etc/ssh/sshd_config
   # Set: PasswordAuthentication no
   sudo systemctl restart sshd
   ```
4. **Enable fail2ban**:
   ```bash
   sudo apt install fail2ban -y
   sudo systemctl enable fail2ban
   ```

## 🐛 Troubleshooting

### Cannot connect to droplet
```bash
# Check if droplet is running
terraform show | grep status

# Check firewall rules
terraform show | grep firewall -A 20
```

### Cannot access database
```bash
# Verify database firewall allows your droplet
terraform show | grep database_firewall -A 10

# Test from droplet
ssh root@<droplet_ip>
nc -zv <postgres_private_host> 25060
```

### Cloud-init script failed
```bash
# Check logs
ssh root@<droplet_ip>
cat /var/log/cloud-init-output.log
journalctl -u cloud-init
```

## 📚 Additional Resources

- [Terraform DigitalOcean Provider](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs)
- [DigitalOcean VPC](https://docs.digitalocean.com/products/networking/vpc/)
- [DigitalOcean Managed Databases](https://docs.digitalocean.com/products/databases/)
- [Cloud Firewalls](https://docs.digitalocean.com/products/networking/firewalls/)

## 📝 Notes

- Semua service akan di-deploy via Docker containers
- Database credentials tersimpan di Terraform state (jaga keamanannya)
- Backup terraform.tfstate secara regular
- Private network IP range: 10.10.0.0/16

## 👥 Support

Untuk issue atau pertanyaan, hubungi DevOps team.

---

**Created**: November 2025  
**Terraform Version**: >= 1.0  
**DigitalOcean Provider**: ~> 2.40
