module "backend" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "${var.project_name}-${var.environment}-${var.common_tags.Component}"

  instance_type          = "t3.micro"

root_block_device = {
  size                  = 20
  type                  = "gp3"
  delete_on_termination = true
}
  vpc_security_group_ids = [data.aws_ssm_parameter.backend_sg_id.value]
  subnet_id              = local.private_subnet_id
  ami                    = data.aws_ami.ami_info.id
  key_name               = aws_key_pair.backend_key.key_name




  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-${var.common_tags.Component}"
  })
}


# ---------------------------
# KEY PAIR (optional but OK if you use SSH manually)
# ---------------------------
resource "aws_key_pair" "backend_key" {
  key_name   = "${var.project_name}-${var.environment}-backend-key"
  public_key = tls_private_key.backend.public_key_openssh
}

resource "tls_private_key" "backend" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "null_resource" "backend" {

  triggers = {
    instance_id = module.backend.id,
     git_commit = var.git_commit
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = tls_private_key.backend.private_key_pem
    host        = module.backend.private_ip
  }

  # Upload main script
  provisioner "file" {
    source      = "${var.common_tags.Component}.sh"
    destination = "/tmp/${var.common_tags.Component}.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "set -euxo pipefail",
      "ls -l /tmp",
      "chmod +x /tmp/${var.common_tags.Component}.sh",
      "bash -x /tmp/${var.common_tags.Component}.sh ${var.common_tags.Component} ${var.environment}",
      "cd /opt/localhelp/backend",
      "git pull origin main",
      "mvn clean package -DskipTests",
      "sudo systemctl restart backend"
    ]
  }
}