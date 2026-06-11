resource "aws_ssm_parameter" "vpn_private_key" {
  name  = "/${var.project_name}/${var.environment}/vpn/private_key"
  type  = "SecureString"
  value = tls_private_key.vpn.private_key_pem
}