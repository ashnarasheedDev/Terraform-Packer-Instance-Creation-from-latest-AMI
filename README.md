Packer is a tool that can build machine images for multiple platforms, including Amazon EC2. Here are the general steps to achieve this workflow:

Create a Packer template (usually in JSON or HCL format) that defines the configuration for building the machine image. This includes specifying the source image, provisioners, and other settings. Within the Packer template, you can use provisioners like shell scripts or configuration management tools to customize the image.
Use Packer to build the AMI based on the template. Packer will execute the defined provisioners and create the desired machine image in your AWS account.

Use Packer to build the AMI based on the template. Packer will execute the defined provisioners and create the desired machine image in your AWS account.

Write the Terraform configuration to provision and launch EC2 instances using the latest AMI created by Packer. This can be done by using the argument most_recent and by applying some filters.

Later fetch zone details and add a route53 record to point the domain name to EIP of instance