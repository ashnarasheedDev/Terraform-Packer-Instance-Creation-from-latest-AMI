## fetching zone details
 
data "aws_route53_zone" "my_zone" {
  name         = var.domain_name
  private_zone = false
}
 
 
## fetchng the most recent ami id
 
data "aws_ami" "latest_ami" {
  most_recent = true               #----------> Retrieve the most recent AMI. Includes filters to narrow down the search for the desired AMI
 
  filter {
    name   = "name"
    values = ["my-project-dev-*"]
  }
 
  filter {
    name   = "tag:project"
    values = ["my-project"]
  }
 
  filter {
    name   = "tag:env"
    values = ["dev"]
  }
 
 
  owners = ["self"]
}
