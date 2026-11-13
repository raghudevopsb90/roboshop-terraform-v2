# roboshop-terraform-v2

Multi-environment Terraform for RoboShop. No Terraform modules. The root `Makefile` is the reference file from `19-multi-env-code-structure` and is not modified.

Databases stay one EC2 instance each. Each application component runs as two EC2 instances behind its own Application Load Balancer.

## Layout

| Component | Instances | Load balancer | Route53 |
|---|---|---|---|
| `mysql`, `mongodb`, `valkey`, `rabbitmq` | 1 | none | A record to the instance private IP |
| `frontend` | 2, in one target group | public (internet-facing) | CNAME to the public load balancer DNS name |
| `catalogue`, `user`, `cart`, `shipping`, `payment`, `notification`, `orders`, `ratings` | 2 each, in that component's target group | private (`internal = true`) | CNAME to that internal load balancer DNS name |

`internal` is set with `each.key != "frontend"`. That comparison is a boolean: `false` for frontend, so its load balancer is public, and `true` for every other application, so those load balancers are private.

A CNAME has to point at a hostname. The target is `aws_lb.applications[each.key].dns_name`. The frontend name resolves to public addresses. An internal load balancer name (`internal-....elb.amazonaws.com`) resolves to private addresses.

Application instance ports accept traffic only from their load balancer security group. The frontend load balancer allows port 80 from the internet. Private load balancers allow their component port from the VPC CIDR. SSH (22) stays open on every instance so Ansible can connect to the public IP from outside the VPC.

## Apply order

1. Database instances, then their A records.
2. Database Ansible (`null_resource.databases`) only after those A records exist.
3. Application instances, target groups, and load balancers. Instances wait until database Ansible has finished.
4. Target-group attachments and listeners.
5. Application CNAME records, after the listeners and attachments exist.
6. Application Ansible (`null_resource.applications`) on each replica only after those CNAME records exist.

## Plan and apply

`terraform init` uses the local backend. Pass both environment files explicitly. Nested `.auto.tfvars` files are not loaded automatically.

```bash
terraform init

terraform plan \
  -var-file="env-dev/ec2.auto.tfvars" \
  -var-file="env-dev/route53.auto.tfvars"

terraform apply \
  -var-file="env-dev/ec2.auto.tfvars" \
  -var-file="env-dev/route53.auto.tfvars"
```

## Makefile conflict

The copied Makefile still runs:

```make
terraform init -backend-config=env-$(env)/state.tfvars
terraform plan -var-file=env-$(env)/main.tfvars
```

This project does not include `env-dev/state.tfvars`, an S3 backend, or `env-dev/main.tfvars`. EC2 and Route53 inputs stay in separate files, so `make plan` cannot load them. `make apply` would copy `env-dev/*.auto.tfvars` into the root and Terraform would auto-load those copies, but only after `make init` succeeds. Use the commands above.

## Known conflicts

- Ansible roles call hosts such as `mysql.rdevopsb90.online`. These records are `mysql-dev.rdevopsb90.online`, as required. Catalogue, shipping, and the other service units will not resolve their backends until unsuffixed records exist in the same zone.
- SSH provisioning uses the instance public IP. Database private IPs are used only for their Route53 A records. Terraform runs outside the VPC, so a private-IP SSH target is not reachable.
- `ami-0eec78ea4cbaaf5bd` is available in `us-east-1` only. That is the region in `env-dev/ec2.auto.tfvars`.
- Hosted zone `Z05126561EI2V4JVVXVBY` is not visible to IAM user `skalluru` in account `973714476881`. The only zone in this account is `learndevopsonline.com` (`Z01881573D6X7ZJV76YYR`). Apply will fail on the Route53 records until this account can change `rdevopsb90.online`.
