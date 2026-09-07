# oficina-db-infra

Infraestrutura do **banco de dados gerenciado** (Terraform) do **Tech Challenge Fase 3 — Oficina Mecânica**. É o **repositório 3 de 4**: provisiona um **Amazon RDS for PostgreSQL 16** dentro da VPC criada pelo repo 2, consumido pela aplicação Laravel (repo 4) e pela Lambda de autenticação (repo 1).

| Repo | Papel |
|---|---|
| [oficina-k8s-infra](https://github.com/MicaelHernandes/oficina-k8s-infra) | VPC, EKS, ECR, ALB, DNS/TLS, monitoring, OIDC |
| **oficina-db-infra** (este) | RDS PostgreSQL gerenciado |
| [oficina-auth-lambda](https://github.com/MicaelHernandes/oficina-auth-lambda) | Lambda de auth por CPF + API Gateway |
| [oficina-api](https://github.com/MicaelHernandes/oficina-api) | Aplicação Laravel no EKS |

## Tecnologias

- **Terraform** (backend S3 + lock DynamoDB), provider `aws`, `random`.
- **Amazon RDS for PostgreSQL 16**, `db.t4g.micro`, 20 GB gp3, single-AZ, **não público**.
- **AWS Secrets Manager** para a senha master.
- **SSM Parameter Store** (`/oficina/db/*`) para expor endpoint/secret aos demais repos.

## Arquitetura

```mermaid
flowchart LR
  subgraph VPC["VPC do repo 2"]
    subgraph Priv["Subnets privadas"]
      RDS[("RDS PostgreSQL 16\ndb.t4g.micro\ndb: oficina")]
    end
    EKS["Nós EKS (app)"] -->|5432| RDS
    L["Lambda auth (repo 1)"] -.->|5432 (regra add. pelo repo 1)| RDS
  end
  SM["Secrets Manager\n/oficina/rds/master"] -.-> RDS
  SSM["SSM /oficina/db/*"] -.-> RDS
```

O SG do RDS abre a porta 5432 **apenas** para o SG dos nós EKS. A regra para o SG da Lambda é criada pelo **repo 1** (que lê `/oficina/db/security_group_id`).

## Dependência de ordem

Lê os outputs do **repo 2** via `terraform_remote_state` (S3): `vpc_id`, `private_subnet_ids`, `node_security_group_id`. Portanto o **repo 2 precisa ter sido aplicado antes**. Ordem global: **2 → 3 → 1 → 4**.

## Documentação

- [`docs/er.md`](docs/er.md) — diagrama ER (Mermaid) do modelo relacional.
- [`docs/rfc-002-rds-postgresql.md`](docs/rfc-002-rds-postgresql.md) — RFC "Por que RDS PostgreSQL".

## Como validar localmente (sem custo)

```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
```

> `terraform apply` **não** roda localmente — só no GitHub Actions (`deploy.yml`, branch `master`). Um `plan` real requer credenciais AWS (OIDC) e o state do repo 2.

## Deploy (automático)

- **`ci.yml`** (PR e push em `homolog`/`master`): fmt, validate, tflint, `plan` comentado no PR. Sem apply.
- **`deploy.yml`** (push em `master`, `environment: production`): `terraform apply`.

Requer o secret **`AWS_ROLE_ARN`** (role OIDC criada pelo repo 2 — `oficina-gha-oficina-db-infra`) e o environment `production` configurados no repo.

## Outputs (também no SSM `/oficina/db/*`)

`rds_endpoint`, `rds_address`, `rds_port`, `db_name`, `secret_arn`, `security_group_id`.

Formato do secret `/oficina/rds/master`:

```json
{ "username": "...", "password": "...", "engine": "postgres", "host": "...", "port": 5432, "dbname": "oficina" }
```

## Custo

`db.t4g.micro` + 20 GB gp3: dentro do Free Tier. **Destruir após a apresentação** (`terraform destroy`).
