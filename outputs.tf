output "instance_ids" {
  description = "EC2 instance IDs. Databases have one instance. Each application has two."
  value = merge(
    { for name, instance in aws_instance.databases : name => instance.id },
    { for name, instance in aws_instance.applications : name => instance.id },
  )
}

output "private_ips" {
  description = "Private IP addresses for database instances and both replicas of each application."
  value = merge(
    { for name, instance in aws_instance.databases : name => instance.private_ip },
    { for name, instance in aws_instance.applications : name => instance.private_ip },
  )
}

output "public_ips" {
  description = "Public IP addresses for database instances and both replicas of each application."
  value = merge(
    { for name, instance in aws_instance.databases : name => instance.public_ip },
    { for name, instance in aws_instance.applications : name => instance.public_ip },
  )
}

output "dns_records" {
  description = "Route53 record names. Databases are A records. Applications are CNAMEs."
  value = merge(
    { for name, record in aws_route53_record.databases : name => record.fqdn },
    { for name, record in aws_route53_record.applications : name => record.fqdn },
  )
}

output "dns_private_ip_mapping" {
  description = "Database DNS name to instance private IP."
  value = {
    for name, record in aws_route53_record.databases : record.fqdn => aws_instance.databases[name].private_ip
  }
}

output "application_dns_targets" {
  description = "Application CNAME target. Frontend points at the public load balancer DNS name. The other components point at their internal load balancer DNS name."
  value = {
    for name, record in aws_route53_record.applications : record.fqdn => aws_lb.applications[name].dns_name
  }
}

output "load_balancers" {
  description = "Application load balancers. Frontend is internet-facing. Every other component is internal."
  value = {
    for name, lb in aws_lb.applications : name => {
      dns_name = lb.dns_name
      internal = lb.internal
      arn      = lb.arn
    }
  }
}

output "default_vpc_id" {
  description = "Default VPC used by the RoboShop instances."
  value       = data.aws_vpc.default.id
}

output "environment" {
  description = "Deployment environment."
  value       = var.environment
}
