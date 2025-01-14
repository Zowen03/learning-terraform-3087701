data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["bitnami-tomcat-*-x86_64-hvm-ebs-nami"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["979382823631"] # Bitnami
}

module "web_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "dev_tf"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.app_ami.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [module.web_sg.security_group_id]

  subnet_id = module.web_vpc.public_subnets[0]

  tags = {
    Name = "HelloWorld"
  }
}

module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name    = "web-alb"
  vpc_id  = module.web_vpc.vpc_id
  subnets = module.web_vpc.public_subnets

  # Security Group
  security_groups = module.web_sg.security_group_id

  target_groups = {
    ex-instance = {
      name_prefix      = "web"
      protocol         = "HTTP"
      port             = 80
      target_type      = "instance"
       my_target  = {
        target_id = aws_instance.web.id
       }
    }
  }


  tags = {
    Environment = "dev"
    
  }
}

module "web_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.13.0"

  vpc_id  = module.web_vpc.vpc_id
  name    = "web"
  ingress_rules = ["https-443-tcp","http-80-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}

