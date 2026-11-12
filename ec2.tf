resource "aws_instance" "databases" {
  for_each = local.databases

  ami                         = var.ami_id
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.roboshop[each.key].id]
  associate_public_ip_address = true

  tags = merge(local.common_tags, {
    Name      = "${each.key}-${var.environment}"
    component = each.key
  })
}

resource "aws_instance" "applications" {
  for_each   = local.application_instances
  depends_on = [aws_instance.databases, null_resource.databases]

  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = element(local.default_subnet_ids, each.value.index)
  vpc_security_group_ids      = [aws_security_group.roboshop[each.value.component].id]
  associate_public_ip_address = true

  tags = merge(local.common_tags, {
    Name      = "${each.key}-${var.environment}"
    component = each.value.component
  })
}
