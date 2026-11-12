locals {
  common_tags = {
    project = "roboshop"
    env     = var.environment
  }

  databases = {
    mysql    = { port = 3306 }
    mongodb  = { port = 27017 }
    valkey   = { port = 6379 }
    rabbitmq = { port = 5672 }
  }

  applications = {
    frontend     = { port = 80 }
    catalogue    = { port = 8002 }
    user         = { port = 8001 }
    cart         = { port = 8003 }
    shipping     = { port = 8004 }
    payment      = { port = 8005 }
    notification = { port = 8008 }
    orders       = { port = 8007 }
    ratings      = { port = 8006 }
  }

  application_instance_count = 2

  application_instances = {
    for pair in setproduct(keys(local.applications), range(local.application_instance_count)) :
    "${pair[0]}-${pair[1] + 1}" => {
      component = pair[0]
      index     = pair[1]
      port      = local.applications[pair[0]].port
    }
  }

  default_subnet_ids = sort(data.aws_subnets.default.ids)

  components = merge(local.databases, local.applications)
}
