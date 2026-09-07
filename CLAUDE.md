# Convenções — oficina-db-infra

Repositório 3 de 4 do Tech Challenge Fase 3. Provisiona o banco gerenciado
(Amazon RDS PostgreSQL 16) na VPC criada pelo repo 2.

## Regras

- **`terraform apply` roda SÓ no GitHub Actions** (branch `master`, `deploy.yml`).
  Localmente só `init`, `fmt`, `validate`, `plan`.
- Lê rede/EKS do repo 2 via `terraform_remote_state` (S3). Requer que o repo 2
  já tenha sido aplicado (ordem 2 → 3 → 1 → 4).
- SG do RDS abre 5432 só do SG dos nós EKS. A regra do SG da Lambda é
  adicionada pelo **repo 1** (que lê `/oficina/db/security_group_id` no SSM).
- Senha do banco gerada pelo Terraform e guardada no Secrets Manager
  (`/oficina/rds/master`); nunca commitar segredos.
- Backend S3 `oficina-tfstate-909314263457`, lock DynamoDB `oficina-tflock`.

## Schema da aplicação

Ver `docs/er.md`. Atenção: a tabela `customers` usa a coluna **`document`**
(CPF/CNPJ), não `cpf`; "inativo" é soft delete (`deleted_at`), não há coluna
`status`. Isso importa para a Lambda de auth (repo 1).
