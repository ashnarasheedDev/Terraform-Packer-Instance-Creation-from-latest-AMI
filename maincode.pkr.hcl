source "amazon-ebs" "zomato" {    #--------> source block specifies the details for the amazon-ebs builder,such as region, source AMI, instance type, SSH username.
 
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
 
build {                                     #-------->  Indicates the build steps.
 
  sources = ["source.amazon-ebs.zomato"]
  provisioner "shell" {                     #-------->  provisioner block inside the build block utilizes the shell provisioner to execute a shell script called "userdata.sh".
 
    script          = "userdata.sh"
    execute_command = "sudo {{.Path}}"      #--------> The execute_command attribute specifies the command to run the shell script with elevated privileges.
  }
}
