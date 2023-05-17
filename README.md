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

