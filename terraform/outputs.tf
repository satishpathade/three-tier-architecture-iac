output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_url" {
  description = "URL of the Application Load Balancer"
  value       = "http://${aws_lb.main.dns_name}"
}

output "ec2_instance_ids" {
  description = "EC2 Instance IDs"
  value       = aws_instance.app[*].id
}

output "ec2_private_ips" {
  description = "Private IPs of EC2 instances"
  value       = aws_instance.app[*].private_ip
}

output "ec2_public_ips" {
  description = "Public IPs of EC2 instances"
  value       = aws_eip.app[*].public_ip
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.main.endpoint
}

output "rds_address" {
  description = "RDS address"
  value       = aws_db_instance.main.address
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}

output "db_username" {
  description = "Database username"
  value       = aws_db_instance.main.username
  sensitive   = true
}

output "ssh_connection_commands" {
  description = "SSH commands to connect to EC2 instances"
  value = [
    for i, ip in aws_eip.app[*].public_ip :
    "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${ip}"
  ]
}