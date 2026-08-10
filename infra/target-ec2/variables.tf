variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "jenkins-terraform-ec2"
}

variable "instance_type" {
  description = "Instance type for the target EC2"
  type        = string
  default     = "t3.micro"
}

variable "ssh_public_key" {
  description = "SSH public key for the target EC2 key pair"
  type        = string
  sensitive   = true
}

variable "ami_owner" {
  description = "Owner ID for Ubuntu AMI"
  type        = string
  default     = "099720109477" # Canonical
}
