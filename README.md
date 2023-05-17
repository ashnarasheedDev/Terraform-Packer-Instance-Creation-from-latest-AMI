## Decsription

Packer is a tool that can build machine images for multiple platforms, including Amazon EC2. Here are the general steps to achieve this workflow:

Create a Packer template (usually in JSON or HCL format) that defines the configuration for building the machine image. This includes specifying the source image, provisioners, and other settings. Within the Packer template, you can use provisioners like shell scripts or configuration management tools to customize the image.
Use Packer to build the AMI based on the template. Packer will execute the defined provisioners and create the desired machine image in your AWS account.

Use Packer to build the AMI based on the template. Packer will execute the defined provisioners and create the desired machine image in your AWS account.

Write the Terraform configuration to provision and launch EC2 instances using the latest AMI created by Packer. This can be done by using the argument most_recent and by applying some filters.

Later fetch zone details and add a route53 record to point the domain name to EIP of instance

**Let's go through the code step by step**

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
**Configuration for building an Amazon Machine Image (AMI) using Packer**
 
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
