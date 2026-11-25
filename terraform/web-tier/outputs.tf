output "site_url" {
  description = "Open this in a browser"
  value       = "http://${aws_lb.web.dns_name}"
}

output "alb_dns_name" {
  value = aws_lb.web.dns_name
}

output "autoscaling_group" {
  value = aws_autoscaling_group.web.name
}

output "web_security_group_id" {
  value = aws_security_group.web.id
}
