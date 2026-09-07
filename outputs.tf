# ---------------------------------------------------------------------------
# Outputs + espelho no SSM (/oficina/db/*) para consumo pelos repos 1 e 4.
# ---------------------------------------------------------------------------

output "rds_endpoint" {
  description = "Endpoint (host:port) da instância RDS."
  value       = aws_db_instance.this.endpoint
}

output "rds_address" {
  description = "Host da instância RDS."
  value       = aws_db_instance.this.address
}

output "rds_port" {
  description = "Porta da instância RDS."
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Nome do banco de dados."
  value       = var.db_name
}

output "secret_arn" {
  description = "ARN do secret com as credenciais master."
  value       = aws_secretsmanager_secret.master.arn
}

output "security_group_id" {
  description = "SG do RDS (o repo 1 anexa a regra da Lambda aqui)."
  value       = aws_security_group.rds.id
}

# --- SSM Parameter Store ---------------------------------------------------
resource "aws_ssm_parameter" "endpoint" {
  name  = "/oficina/db/endpoint"
  type  = "String"
  value = aws_db_instance.this.address
  tags  = local.tags
}

resource "aws_ssm_parameter" "port" {
  name  = "/oficina/db/port"
  type  = "String"
  value = tostring(aws_db_instance.this.port)
  tags  = local.tags
}

resource "aws_ssm_parameter" "name" {
  name  = "/oficina/db/name"
  type  = "String"
  value = var.db_name
  tags  = local.tags
}

resource "aws_ssm_parameter" "secret_arn" {
  name  = "/oficina/db/secret_arn"
  type  = "String"
  value = aws_secretsmanager_secret.master.arn
  tags  = local.tags
}

resource "aws_ssm_parameter" "security_group_id" {
  name  = "/oficina/db/security_group_id"
  type  = "String"
  value = aws_security_group.rds.id
  tags  = local.tags
}
