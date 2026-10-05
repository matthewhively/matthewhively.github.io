---
name: aws-infrastructure
description: >-
  Use whenever discussing AWS infrastructure, troubleshooting, deployment,
  and Terraform work. Includes IAM, EC2, Aurora MySQL, ElastiCache,
  Lambda, networking, and AWS CLI profiles. Also use when Ruby or
  Rails work directly involves AWS resources.
---

When using this skill, state “Using skill: aws-infrastructure”
before proceeding. Announce once per task, not on every response.

Before performing this workflow, read and apply
../../references/common.md

Assume the following unless otherwise stated:
- Our cloud infrastructure is running in AWS US-east-1 region
- We only ever run on the standard AWS partition, never us-gov or china
- Any and all references to services should be viewed through an AWS ecosystem

Our organization has 2 accounts that we use day to day:
VizProd - 873143145291 
VizLabs - 807374381268 (experimental staging, testing and development servers)
On my local laptop I have IAM access tokens for both accounts setup under profiles `vizlabs` and `vizprod` respectively.

Our organization is slowly adopting Terraform as our Infrastructure as Code (IaC) tool of choice, but most things are not defined there yet.

Our production servers run on ec2 instances that are running ubuntu 26.04 AMI.
We also make use of
- Aurora-RDS-MySQL cluster
- Elasticache Memcached cluster
- Elasticache Redis cluster
- Autoscaling groups
- Launch templates
- Automation Documents
- Command Documents
- Systems Manager Parameter Store

Whenever writing a cloud function (lambda or some other service) prefer to use the ruby language because that is what we are most familiar with.
Only use another language (python, nodejs etc) if it is any of these:
- Impossible otherwise
- Substantially more streamlined
- much faster
- much easier to read
