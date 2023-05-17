##loading keypair module
 
module "key" {
 
  source     = "/home/ec2-user/key-module/"
  my_project = var.project_name
  my_env     = var.env
  region     = var.region
}
 
## creating an instance
 
resource "aws_instance" "webserver" {
  ami                    = data.aws_ami.latest_ami.id    #-------> latest ami is used
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
 
## creating security group
 
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
 
 
## creating eip for instance
 
resource "aws_eip" "webserver" {
  instance = aws_instance.webserver.id
  vpc      = true
}
 
 
## pointing webserver-mumbai.ashna.online to eip
 
resource "aws_route53_record" "webserver" {
  zone_id = data.aws_route53_zone.my_zone.id
  name    = var.record_name
  type    = "A"
  ttl     = 300
  records = [aws_eip.webserver.public_ip]
}
