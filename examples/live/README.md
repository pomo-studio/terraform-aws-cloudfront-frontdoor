# Frontdoor live

Apply the frontdoor module against real AWS resources in an acceptance run.

## What it creates

- A VPC with DNS support and an internet gateway. CloudFront VPC origins require the gateway.
- Two subnets across available zones and a security group that allows HTTP inside the VPC.
- An internal application load balancer, a target group, and an HTTP listener.
- A CloudFront VPC origin pointed at the load balancer.
- A frontdoor distribution with one blue deployment. Logging is off.

## Before you start

- Provider `hashicorp/aws`. Credentials must have permission to create VPC, ELB, and CloudFront resources.
- Uses a local source, `../../`.
- Variables `name` and `region` are set here. The acceptance workflow applies and later destroys this example, so it creates its own prerequisites.

## Run it

```bash
terraform init
terraform plan
terraform apply
```

## Clean up

```bash
terraform destroy
```
