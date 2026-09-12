variable "region" {
  description = "Região AWS."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Prefixo do projeto."
  type        = string
  default     = "oficina"
}

variable "db_name" {
  description = "Nome do banco de dados da aplicação."
  type        = string
  default     = "oficina"
}

variable "db_username" {
  description = "Usuário master do RDS."
  type        = string
  default     = "oficina_admin"
}

variable "db_engine_version" {
  description = "Versão do PostgreSQL."
  type        = string
  default     = "16.4"
}

variable "db_instance_class" {
  description = "Classe da instância RDS (free tier: db.t4g.micro)."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "Armazenamento em GB."
  type        = number
  default     = 20
}

variable "backup_retention_period" {
  description = "Dias de retenção de backup. O Free plan da conta limita a retenção (CreateDBInstance falha com FreeTierRestrictionError acima do teto)."
  type        = number
  default     = 1
}
