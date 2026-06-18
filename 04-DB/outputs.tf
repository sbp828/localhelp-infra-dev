output "zone_name" {
  value = data.aws_route53_zone.main.name
}

output "db_secret_arn" {
  value = module.db.db_instance_master_user_secret_arn
}

output "db_endpoint" {
  value = module.db.db_instance_endpoint
}