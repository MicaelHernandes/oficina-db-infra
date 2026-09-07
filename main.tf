# ---------------------------------------------------------------------------
# Banco de dados gerenciado — Amazon RDS for PostgreSQL 16.
#
# - Subnet group nas subnets PRIVADAS da VPC do repo 2 (sem acesso público).
# - SG permite 5432 apenas do SG dos nós EKS. A regra para o SG da Lambda
#   (repo 1) é adicionada pelo próprio repo 1 (que só existe depois deste),
#   lendo o security_group_id exposto via SSM/output.
# - Senha aleatória guardada no Secrets Manager (/oficina/rds/master).
# - Instância single-AZ, db.t4g.micro (free tier), 20 GB gp3, backup 7 dias.
# ---------------------------------------------------------------------------

resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-db"
  subnet_ids = local.private_subnet_ids
  tags       = local.tags
}

resource "aws_security_group" "rds" {
  name        = "${var.project}-rds"
  description = "Acesso ao RDS PostgreSQL da Oficina"
  vpc_id      = local.vpc_id
  tags        = local.tags
}

# Ingress 5432 a partir do SG dos nós EKS (aplicação Laravel).
resource "aws_security_group_rule" "from_eks_nodes" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = local.node_security_group_id
  description              = "PostgreSQL a partir dos nos do EKS"
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.rds.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Egress liberado"
}

# --- Senha e secret -------------------------------------------------------
resource "random_password" "master" {
  length  = 24
  special = false # evita caracteres que quebram a connection string do RDS
}

resource "aws_secretsmanager_secret" "master" {
  name = "/oficina/rds/master"
  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "master" {
  secret_id = aws_secretsmanager_secret.master.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.master.result
    engine   = "postgres"
    host     = aws_db_instance.this.address
    port     = aws_db_instance.this.port
    dbname   = var.db_name
  })
}

# --- Instância RDS --------------------------------------------------------
resource "aws_db_instance" "this" {
  identifier     = "${var.project}-postgres"
  engine         = "postgres"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  db_name  = var.db_name
  username = var.db_username
  password = random_password.master.result

  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  multi_az               = false
  publicly_accessible    = false

  backup_retention_period = var.backup_retention_period
  deletion_protection     = false
  skip_final_snapshot     = true
  apply_immediately       = true

  tags = local.tags
}
