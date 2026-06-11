module "vpn" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "${var.project_name}-${var.environment}-vpn"

  instance_type           = "t3.micro"
  vpc_security_group_ids  = [data.aws_ssm_parameter.vpn_sg_id.value]
  subnet_id               = local.public_subnet_id
  ami                     = data.aws_ami.ubuntu.id
  key_name                = aws_key_pair.vpn_key.key_name
  associate_public_ip_address = true
  

  depends_on = [
    aws_key_pair.vpn_key,
    aws_ssm_parameter.vpn_private_key
  ]

  user_data = file("${path.module}/userdata.sh")


  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-vpn"
    }

  )
}

resource "tls_private_key" "vpn" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "vpn_key" {
  key_name   = "${var.project_name}-${var.environment}-vpn-key"
  public_key = tls_private_key.vpn.public_key_openssh
}