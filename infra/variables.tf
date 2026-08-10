variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name prefix for all resources"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key material for the EC2 key pair"
  type        = string
  sensitive   = true
}

variable "instance_type" {
  description = "EC2 instance type for Jenkins"
  type        = string
  default     = "t3.medium"
}

variable "ami_owner" {
  description = "Owner ID for Ubuntu AMI lookup"
  type        = string
  default     = "099720109477" # Canonical
}
