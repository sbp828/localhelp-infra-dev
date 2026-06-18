module "backend" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "${var.project_name}-${var.environment}-${var.common_tags.Component}"

  instance_type          = "t3.micro"

root_block_device = {
  size                  = 40
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
    # git_commit = var.git_commit
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
      "sudo git config --global --add safe.directory /opt/localhelp/backend"
    ]
  }
}

resource "aws_ec2_instance_state" "backend_stop" {
  instance_id = module.backend.id
  state       = "stopped"
  depends_on  = [ null_resource.backend ]
}

resource "aws_ami_from_instance" "backend_ami" {
  name               = "${var.project_name}-${var.environment}-${var.common_tags.Component}"
  source_instance_id = module.backend.id

  depends_on = [ aws_ec2_instance_state.backend_stop ]
}

resource "null_resource" "backend_delete" {
 triggers = {
      instance_id = module.backend.id # this will be triggered everytime instance is created
    }

  provisioner "local-exec" {
    command = "aws ec2 terminate-instances --instance-ids ${module.backend.id}"
  }


  depends_on = [ aws_ami_from_instance.backend_ami ]
}

resource "aws_lb_target_group" "backend" {
  name     = "${var.project_name}-${var.environment}-${var.common_tags.Component}"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_ssm_parameter.vpc_id.value
   health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

resource "aws_launch_template" "backend" {
  name = "${var.project_name}-${var.environment}-${var.common_tags.Component}"

  image_id = aws_ami_from_instance.backend_ami.id

  instance_initiated_shutdown_behavior = "terminate"

  instance_type = "t3.micro"
  update_default_version = true

  vpc_security_group_ids = [ data.aws_ssm_parameter.backend_sg_id.value ]

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      var.common_tags,
      {
      Name = "${var.project_name}-${var.environment}-${var.common_tags.Component}"
      }
    )
  }
}

resource "aws_autoscaling_group" "backend" {
  name                      = "${var.project_name}-${var.environment}-${var.common_tags.Component}"
  max_size                  = 5
  min_size                  = 1
  health_check_grace_period = 60
  health_check_type         = "ELB"
  desired_capacity          = 1
  
  launch_template {
    id      = aws_launch_template.backend.id
    version = "$Latest"
  }
  vpc_zone_identifier       = split(",",data.aws_ssm_parameter.private_subnet_ids.value)

  instance_refresh {
    strategy = "Rolling"
    preferences{
      min_healthy_percentage = 50
    }
    triggers = ["launch_template"]
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-${var.common_tags.Component}"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }

  tag {
    key                 = "Project"
    value               = "${var.project_name}"
    propagate_at_launch = false
  }
}