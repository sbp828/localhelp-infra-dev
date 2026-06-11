resource "aws_ssm_parameter" "backend_private_key" {
  name  = "/${var.project_name}/${var.environment}/backend/private_key"
  type  = "SecureString"
  value = tls_private_key.backend.private_key_pem
}



