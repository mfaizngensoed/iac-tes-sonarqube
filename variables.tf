# DigitalOcean Token
variable "do_token" {
  description = "DigitalOcean API Token"
  type        = string
  sensitive   = true
}

# SSH Key
variable "pvt_key" {
  description = "Path to private SSH key for connecting to droplets"
  type        = string
}

variable "ssh_key_name" {
  description = "Name of the SSH key in DigitalOcean"
  type        = string
  default     = "key-terraform"
}

# Region
variable "region" {
  description = "DigitalOcean region"
  type        = string
  default     = "sgp1"
}

# Droplet Configuration
variable "droplet_size" {
  description = "Size of the droplets"
  type        = string
  default     = "s-1vcpu-1gb"
}

variable "droplet_image" {
  description = "Operating system image for droplets"
  type        = string
  default     = "ubuntu-24-04-x64"
}

# Database Configuration
variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "simut_db"
}

variable "db_user" {
  description = "PostgreSQL database username"
  type        = string
  default     = "simut"
}

variable "db_password" {
  description = "PostgreSQL database password"
  type        = string
  sensitive   = true
}

variable "db_size" {
  description = "Size of the PostgreSQL cluster"
  type        = string
  default     = "db-s-1vcpu-1gb"
}

variable "db_engine_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "16"
}

# Management IP (untuk akses SSH ke ML Node)
variable "management_ip" {
  description = "IP address allowed for SSH access to ML node (your public IP)"
  type        = string
  default     = "0.0.0.0/0" # CHANGE THIS to your public IP for better security
}

# VPC Configuration
variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "simut-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.10.0.0/16"
}
