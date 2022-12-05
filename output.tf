output "lb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.alb.dns_name
}

output "instance_public_ip" {
  description = "public IP of web server 1"
  value       = aws_instance.web1.public_ip
}

output "instance_public_ip" {
  description = "public IP of web server 2"
  value       = aws_instance.web2.public_ip
}
