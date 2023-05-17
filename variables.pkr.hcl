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
 
locals {
 
  image-timestamp = "${formatdate("DD-MM-YYYY-HH-MM", timestamp())}"         #---------->timestamp function to fecth current timestamp and format it using formatdate
  image-name      = "${var.project_name}-${var.env}-${local.image-timestamp}" # ----------> we will get a unique image-name
                                                                              
}
