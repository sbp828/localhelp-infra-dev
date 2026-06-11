module "db"{
    source           =  "../../terraform-aws-securitygroup"
    project_name     =  var.project_name
    environment      =  var.environment
    sg_description   =  "SG group for db instances of mysql"
    vpc_id           =  data.aws_ssm_parameter.vpc_id.value
    common_tags      =  var.common_tags
    sg_name          =  "db"
}

module "backend"{
    source           =  "../../terraform-aws-securitygroup"
    project_name     =  var.project_name
    environment      =  var.environment
    sg_description   =  "SG group for backend instances "
    vpc_id           =  data.aws_ssm_parameter.vpc_id.value
    common_tags      =  var.common_tags
    sg_name          =  "backend"
}

module "frontend"{
    source           =  "../../terraform-aws-securitygroup"
    project_name     =  var.project_name
    environment      =  var.environment
    sg_description   =  "SG group for frontend instances "
    vpc_id           =  data.aws_ssm_parameter.vpc_id.value
    common_tags      =  var.common_tags
    sg_name          =  "frontend"
}

module "bastion"{
    source           =  "../../terraform-aws-securitygroup"
    project_name     =  var.project_name
    environment      =  var.environment
    sg_description   =  "SG group for bastion instances"
    vpc_id           =  data.aws_ssm_parameter.vpc_id.value
    common_tags      =  var.common_tags
    sg_name          =  "bastion"
}

module "app_alb"{
    source           =  "../../terraform-aws-securitygroup"
    project_name     =  var.project_name
    environment      =  var.environment
    sg_description   =  "SG group for app alb "
    vpc_id           =  data.aws_ssm_parameter.vpc_id.value
    common_tags      =  var.common_tags
    sg_name          =  "app_alb"
}

module "vpn"{
    source           =  "../../terraform-aws-securitygroup"
    project_name     =  var.project_name
    environment      =  var.environment
    sg_description   =  "SG group for vpn"
    vpc_id           =  data.aws_ssm_parameter.vpc_id.value
    common_tags      =  var.common_tags
    sg_name          =  "vpn"
    inbound_rules     =  var.vpn_sg_rules
}

# module "ansible"{
#     source           =  "../../terraform-aws-securitygroup"
#     project_name     =  var.project_name
#     environment      =  var.environment
#     sg_description   =  "SG group for frontend instances"
#     vpc_id           =  data.aws_ssm_parameter.vpc_id.value
#     common_tags      =  var.common_tags
#     sg_name          =  "ansible"
# }

# this rule allows the backend connections to the db 
resource "aws_security_group_rule" "db_backend" {
  type                              = "ingress"
  from_port                         = 3306
  to_port                           = 3306
  protocol                          = "tcp"
  source_security_group_id          = module.backend.sg_id
  security_group_id                 = module.db.sg_id
}

# this rule allows the bastion connections to the db 
resource "aws_security_group_rule" "db_bastion" {
  type                              = "ingress"
  from_port                         = 3306
  to_port                           = 3306
  protocol                          = "tcp"
  source_security_group_id          = module.bastion.sg_id
  security_group_id                 = module.db.sg_id
}

# this rule allows the vpn connections to the db 
resource "aws_security_group_rule" "db_vpn" {
  type                              = "ingress"
  from_port                         = 3306
  to_port                           = 3306
  protocol                          = "tcp"
  source_security_group_id          = module.vpn.sg_id
  security_group_id                 = module.db.sg_id
}

# this rule allows the app_alb  connections to the backend
resource "aws_security_group_rule" "backend_app_alb" {
  type                              = "ingress"
  from_port                         = 8080
  to_port                           = 8080
  protocol                          = "tcp"
  source_security_group_id          = module.app_alb.sg_id
  security_group_id                 = module.backend.sg_id
}

# this rule allows vpn connections to the app_alb
resource "aws_security_group_rule" "app_alb_vpn" {
  type                              = "ingress"
  from_port                         = 80
  to_port                           = 80
  protocol                          = "tcp"
  source_security_group_id          = module.vpn.sg_id
  security_group_id                 = module.app_alb.sg_id
}

# this rule allows the bastion connections to the backend
resource "aws_security_group_rule" "backend_bastion" {
  type                              = "ingress"
  from_port                         = 22
  to_port                           = 22
  protocol                          = "tcp"
  source_security_group_id          = module.bastion.sg_id
  security_group_id                 = module.backend.sg_id
}

#this rule allows the ssh vpn connections to the backend
resource "aws_security_group_rule" "backend_vpn_ssh" {
  type                              = "ingress"
  from_port                         = 22
  to_port                           = 22
  protocol                          = "tcp"
  source_security_group_id          = module.vpn.sg_id
  security_group_id                 = module.backend.sg_id
}

#this rule allows the http vpn connections to the backend
resource "aws_security_group_rule" "backend_vpn_http" {
  type                              = "ingress"
  from_port                         = 8080
  to_port                           = 8080
  protocol                          = "tcp"
  source_security_group_id          = module.vpn.sg_id
  security_group_id                 = module.backend.sg_id
}


# this rule allows the public internet users connections to the frontend
resource "aws_security_group_rule" "frontend_public" {
  type                              = "ingress"
  from_port                         = 80
  to_port                           = 80
  protocol                          = "tcp"
  cidr_blocks                       = ["0.0.0.0/0"]
  security_group_id                 = module.frontend.sg_id
}

# this rule allows the bastion connections to the frontend
resource "aws_security_group_rule" "frontend_bastion" {
  type                              = "ingress"
  from_port                         = 22
  to_port                           = 22
  protocol                          = "tcp"
  source_security_group_id          = module.bastion.sg_id
  security_group_id                 = module.frontend.sg_id
}

# this rule allows the ansible connections to the frontend
# resource "aws_security_group_rule" "frontend_ansible" {
#   type                              = "ingress"
#   from_port                         = 22
#   to_port                           = 22
#   protocol                          = "tcp"
#   source_security_group_id          = module.ansible.sg_id
#   security_group_id                 = module.frontend.sg_id
# }

# this rule allows the public connections to the bastion
resource "aws_security_group_rule" "bastion_public" {
  type                              = "ingress"
  from_port                         = 22
  to_port                           = 22
  protocol                          = "tcp"
  cidr_blocks                       = ["0.0.0.0/0"]
  security_group_id                 = module.bastion.sg_id
}

# this rule allows the public connections to the ansible
# resource "aws_security_group_rule" "ansible_public" {
#   type                              = "ingress"
#   from_port                         = 22
#   to_port                           = 22
#   protocol                          = "tcp"
#   cidr_blocks                       = ["0.0.0.0/0"]
#   security_group_id                 = module.ansible.sg_id
# }
