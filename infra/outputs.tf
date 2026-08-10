output "jenkins_public_ip" {
  description = "Elastic IP address of the Jenkins server"
  value       = aws_eip.jenkins.public_ip
}

output "jenkins_instance_id" {
  description = "EC2 instance ID of the Jenkins server"
  value       = aws_instance.jenkins.id
}

output "jenkins_url" {
  description = "Jenkins web URL (via Nginx)"
  value       = "http://${aws_eip.jenkins.public_ip}"
}
