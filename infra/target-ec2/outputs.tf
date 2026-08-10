output "target_public_ip" {
  description = "Public IP of the target EC2 instance"
  value       = aws_instance.target.public_ip
}

output "target_instance_id" {
  description = "Instance ID of the target EC2"
  value       = aws_instance.target.id
}
