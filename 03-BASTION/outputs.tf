output "ami_id" {
  value = data.aws_ami.ami_info.id
}

output "public_ip" {
  value = module.bastion.public_ip  # single instance
}

output "private_ip" {
  value = module.bastion.private_ip
}

output "private_key_ssm_name" {
  value = aws_ssm_parameter.bastion_private_key.name
}

output "public_ip_ssm_name" {
  value = aws_ssm_parameter.bastion_public_ip.name
}