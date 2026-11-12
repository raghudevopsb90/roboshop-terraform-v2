resource "aws_lb" "applications" {
  for_each = local.applications

  name               = "${each.key}-${var.environment}"
  internal           = each.key != "frontend"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb[each.key].id]
  subnets            = local.default_subnet_ids

  tags = merge(local.common_tags, {
    Name      = "${each.key}-${var.environment}"
    component = each.key
  })
}

resource "aws_lb_target_group" "applications" {
  for_each = local.applications

  name        = "${each.key}-${var.environment}"
  port        = each.value.port
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = merge(local.common_tags, {
    Name      = "${each.key}-${var.environment}"
    component = each.key
  })
}

resource "aws_lb_target_group_attachment" "applications" {
  for_each = local.application_instances

  target_group_arn = aws_lb_target_group.applications[each.value.component].arn
  target_id        = aws_instance.applications[each.key].id
  port             = each.value.port
}

resource "aws_lb_listener" "applications" {
  for_each = local.applications

  load_balancer_arn = aws_lb.applications[each.key].arn
  port              = each.value.port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.applications[each.key].arn
  }
}
