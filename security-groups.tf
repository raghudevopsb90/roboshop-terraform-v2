resource "aws_security_group" "roboshop" {
  for_each = local.components

  name        = "${each.key}-${var.environment}"
  description = "RoboShop ${each.key} ${var.environment} SSH and application access"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    for_each = contains(keys(local.databases), each.key) ? [each.value.port] : []

    content {
      description = "${each.key} application"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  dynamic "ingress" {
    for_each = contains(keys(local.applications), each.key) ? [each.value.port] : []

    content {
      description     = "${each.key} from load balancer"
      from_port       = ingress.value
      to_port         = ingress.value
      protocol        = "tcp"
      security_groups = [aws_security_group.alb[each.key].id]
    }
  }

  egress {
    description = "Allow outbound traffic for package installs and Ansible pull"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name      = "${each.key}-${var.environment}"
    component = each.key
  })
}

resource "aws_security_group" "alb" {
  for_each = local.applications

  name        = "${each.key}-${var.environment}-alb"
  description = "RoboShop ${each.key} ${var.environment} load balancer"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = each.key == "frontend" ? "Public frontend" : "Private ${each.key} from the VPC"
    from_port   = each.value.port
    to_port     = each.value.port
    protocol    = "tcp"
    cidr_blocks = each.key == "frontend" ? ["0.0.0.0/0"] : [data.aws_vpc.default.cidr_block]
  }

  egress {
    description = "Allow outbound traffic to application instances"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name      = "${each.key}-${var.environment}-alb"
    component = each.key
  })
}
