### Decsription

<b>Packer is a tool that can build machine images for multiple platforms, including Amazon EC2. Here are the general steps to achieve this workflow:</b>

Create a Packer template (usually in JSON or HCL format) that defines the configuration for building the machine image. This includes specifying the source image, provisioners, and other settings. Within the Packer template, you can use provisioners like shell scripts or configuration management tools to customize the image.
Use Packer to build the AMI based on the template. Packer will execute the defined provisioners and create the desired machine image in your AWS account.

Use Packer to build the AMI based on the template. Packer will execute the defined provisioners and create the desired machine image in your AWS account.

Write the Terraform configuration to provision and launch EC2 instances using the latest AMI created by Packer. This can be done by using the argument most_recent and by applying some filters.

Later fetch zone details and add a route53 record to point the domain name to EIP of instance



### Pre-requisites:

1. IAM Role (Role needs to be attached on terraform running server)
2. knowledge about AWS services and Packer
3. Terraform and its installation.



**Let's go through the code step by step**


### 1. Setting Up Packer


**Variable Declaration for packer**

In this section, variables are declared with their default values. These variables allow you to customize and provide values when running Terraform commands. The variables defined here include env, project_name, region, source_ami, and instance_type
 
```
variable "env" {
  default = "dev"
}

variable "project_name" {
  default = "my-project"
}

variable "region" {
  default = "ap-south-1"
}

variable "source_ami" {
  default = "ami-0c768662cc797cd75"
}

variable "instance_type" {
  default = "t2.micro"
}
```
**Locals Block**

The locals block is used to define local values that can be reused within the Terraform configuration. The image_timestamp variable is assigned the formatted timestamp using the formatdate() function with the desired date and time format. The timestamp() function provides the current timestamp. The image_name variable is then formed by concatenating the values of var.project_name, var.env, and local.image_timestamp together using the string interpolation syntax ${..}hence gets uique image name.

```
locals {
  image_timestamp = formatdate("DD-MM-YYYY-HH-MM", timestamp())
  image_name      = "${var.project_name}-${var.env}-${local.image_timestamp}"
}
```
### 2. Configuration for building an Amazon Machine Image (AMI) using Packer
 
 Source block specifies the source configuration for building an Amazon EBS-backed AMI. It has the following attributes:
    region: Specifies the region where the AMI will be built, using the value from the var.region variable.
    source_ami: Specifies the base AMI ID to use as the source for the new AMI, using the value from the var.source_ami variable.
    ami_name: Specifies the name of the resulting AMI. In this case, it uses the value from the local.image-name variable, which should be generated in a separate section of the configuration.
    instance_type: Specifies the EC2 instance type to use for building the AMI, using the value from the var.instance_type variable.
    ssh_username: Specifies the username used for SSH connections to the EC2 instances during the build process.
    
   ```
   source "amazon-ebs" "zomato" {
 
  region        = var.region
  source_ami    = var.source_ami
  ami_name      = local.image-name
  instance_type = var.instance_type
  ssh_username  = "ec2-user"
 
  tags = {
    Name    = local.image-name
    project = var.project_name
    env     = var.env
 
  }
}
```
Build block defines the build process for the AMI. It specifies the source as source.amazon-ebs.zomato, which refers to the source configuration defined in the previous block. The provisioner block within the build block specifies a shell script (userdata.sh) to be executed on the EC2 instance during the build process. The execute_command attribute provides the command to execute the script with elevated privileges using sudo {{.Path}}.

```
build {
 
  sources = ["source.amazon-ebs.zomato"]
  provisioner "shell" {
 
    script          = "userdata.sh"
    execute_command = "sudo {{.Path}}"
  }
}

```
#### Lets validate the code using
```sh
packer validate .
```
#### Lets apply the above architecture to the AWS.
```sh
packer apply .
```

### 3. Setting up EC2 instance from the latest AMI using Terraform

**Create a provider.tf file**
```sh
provider "aws" {
  region     = var.region
  
}
```
**Create a variable.tf file**

```
variable "env" {
  default = "dev"
}
 
variable "project_name" {
  default = "my-project"
}
 
variable "region" {
  default = "ap-south-1"
}
 
 
variable "instance_type" {
  default = "t2.micro"
}
 
variable "domain_name" {
  default = "ashna.online"
}
 
variable "record_name" {
  default = "webserver"
}
```
**Datasource to fetch zone details and latest AMI**

> fetching zone details
``` 
data "aws_route53_zone" "my_zone" {
  name         = var.domain_name
  private_zone = false
}
 ```
 
> fetching the most recent ami id
``` 
data "aws_ami" "latest_ami" {
  most_recent = true
 
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
```
> loading keypair module

``` 
module "key" {
 
  source     = "/home/ec2-user/key-module/"
  my_project = var.project_name
  my_env     = var.env
  region     = var.region
}
```
> Creating an instance

> The AMI ID for the instance is set to data.aws_ami.latest_ami.id. This refers to the most recent AMI ID fetched from the data source block named "latest_ami".
 
```
resource "aws_instance" "webserver" {
  ami                    = data.aws_ami.latest_ami.id
  instance_type          = var.instance_type
  key_name               = module.key.key_name
  vpc_security_group_ids = [aws_security_group.webserver.id]
  tags = {
    Name = "${var.project_name}-${var.env}"
  }
  lifecycle {
    create_before_destroy = true
  }
} 
```
> creating security group
 
```
resource "aws_security_group" "webserver" {
  name_prefix = "${var.project_name}-${var.env}-"
 
  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
 
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
 
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
 
  tags = {
    Name = "${var.project_name}-${var.env}"
  }
 
}
 ```
 
> creating eip for instance

``` 
resource "aws_eip" "webserver" {
  instance = aws_instance.webserver.id
  vpc      = true
}
 ```
 
> Pointing webserver.ashna.online to eip of instance
 
```
resource "aws_route53_record" "webserver" {
  zone_id = data.aws_route53_zone.my_zone.id
  name    = var.record_name
  type    = "A"
  ttl     = 300
  records = [aws_eip.webserver.public_ip]
}
```
#### Lets validate the terraform codes using
```sh
terraform validate
```
#### Lets plan the architecture and verify once again.
```sh
terraform plan
```
#### Lets apply the above architecture to the AWS.
```sh
terraform apply
```

----
### Conclusion

This Terraform configuration allows you to provision an EC2 instance from the latest AMI, create a security group, associate an Elastic IP, and configure a Route 53 DNS record for easy access to the instance.
