module "backend" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "${var.project_name}-${var.environment}-${var.common_tags.Component}"

  instance_type           = "t3.micro"
  vpc_security_group_ids  = [data.aws_ssm_parameter.backend_sg_id.value]
  subnet_id               = local.private_subnet_id
  ami                     = data.aws_ami.ami_info.id
  key_name                = aws_key_pair.backend_key.key_name
 # user_data               = file("backend.sh")

  depends_on = [
    aws_key_pair.backend_key,
    aws_ssm_parameter.backend_private_key
  ]




  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-${var.common_tags.Component}"
    }

  )
}




resource "aws_key_pair" "backend_key" {
  key_name   = "${var.project_name}-${var.environment}-backend-key"
  public_key = tls_private_key.backend.public_key_openssh
}

resource "tls_private_key" "backend" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "null_resource" "backend_setup" {
  triggers = {
    backend_id = module.backend.id
  }

  connection {
    type                = "ssh"
    user                = "ec2-user"
    private_key         = aws_ssm_parameter.backend_private_key.value
    host                = module.backend.private_ip
    
  }

  provisioner "file" {
    source      = "backend.sh"
    destination = "/tmp/backend.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/backend.sh",
      "sudo sh /tmp/${var.common_tags.Component}.sh"
    ]
  }

  depends_on = [
    module.backend
  ]
}