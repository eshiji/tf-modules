# Common
variable "project_name" {
  type = string
}
variable "env" {
  type    = string
  default = "dev"
}
variable "tags" {
  type = map(string)
}
variable "ovpn_files_bucket_name" {
  type = string
}

# Network
variable "vpc_id" {
  type = string
}
variable "cidr_block_ssh_whitelist" {
  type = list(string)
}

variable "cidr_block_udp_whitelist" {
  type = list(string)
}

# Instance 
variable "instance_type" {
  type = string
}
variable "ovpn_user" {
  type        = string
  description = "User for openvpn created on user data"
}
variable "public_subnet_id" {
  type        = string
  description = "Subnet id to attach."
}

# Route53
variable "zone_id"{
  type = string
  description = "Zone ID to create the record"
}
variable "domain_name" {
  type = string
  description = "Domain name"
}