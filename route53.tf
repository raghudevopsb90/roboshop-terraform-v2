resource "aws_route53_record" "databases" {
  for_each = local.databases

  zone_id = var.hosted_zone_id
  name    = "${each.key}-${var.environment}.${var.domain_name}"
  type    = "A"
  ttl     = 30
  records = [aws_instance.databases[each.key].private_ip]
}

resource "aws_route53_record" "applications" {
  for_each = local.applications

  depends_on = [
    aws_lb_listener.applications,
    aws_lb_target_group_attachment.applications,
  ]

  zone_id = var.hosted_zone_id
  name    = "${each.key}-${var.environment}.${var.domain_name}"
  type    = "CNAME"
  ttl     = 30
  records = [aws_lb.applications[each.key].dns_name]
}
