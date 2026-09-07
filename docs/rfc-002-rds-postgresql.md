# RFC-002 — Banco de dados gerenciado: Amazon RDS for PostgreSQL

- **Status:** Aceita
- **Data:** 2026-09
- **Contexto:** Tech Challenge Fase 3 — Oficina Mecânica (repo `oficina-db-infra`)

## Contexto

A aplicação Laravel usa PostgreSQL (migrations, tipos `decimal`, soft deletes, `foreignId`). A Fase 3 exige um **banco de dados gerenciado** na nuvem, provisionado por Terraform, consumido tanto pela aplicação no EKS quanto pela Função Serverless de autenticação (repo 1). O ambiente é **único (produção)** e o custo deve caber no crédito de Free Tier da conta.

## Decisão

Usar **Amazon RDS for PostgreSQL 16**, instância **`db.t4g.micro`** (elegível ao Free Tier), 20 GB **gp3**, **single-AZ**, **não pública**, com 1 database `oficina`. Senha gerada pelo Terraform e guardada no **AWS Secrets Manager** (`/oficina/rds/master`). Rede nas **subnets privadas** da VPC do repo 2; acesso 5432 restrito ao **SG dos nós EKS** e ao **SG da Lambda** (regra adicionada pelo repo 1).

## Alternativas consideradas

| Opção | Prós | Contras | Veredito |
|---|---|---|---|
| **RDS PostgreSQL** (escolhida) | Gerenciado (backup, patch, métricas), compatível 1:1 com o app, Free Tier, integra com Secrets Manager e VPC | Menos "cloud-native" que Aurora Serverless | ✅ |
| Aurora Serverless v2 (Postgres) | Escala a zero-ish, alta disponibilidade | Custo mínimo por ACU acima do t4g.micro; complexidade desnecessária para 1 ambiente | ❌ custo |
| PostgreSQL self-hosted no EKS (StatefulSet) | Custo só de EBS | Sem backup/patch gerenciado, durabilidade e operação por nossa conta; contraria o requisito de **banco gerenciado** | ❌ requisito |
| DynamoDB | Serverless, barato | Modelo relacional do app (FKs, joins, decimais) não mapeia; reescrever o domínio | ❌ inviável |

## Justificativa do banco

O domínio é fortemente **relacional**: `order_services` referencia `customers`, `vehicles`, `users` e agrega itens de serviço/peça e um `budget` 1:1; há integridade referencial (FKs com cascade/restrict) e valores monetários `decimal(10,2)`. PostgreSQL atende nativamente, e o app já foi escrito para ele. Ver o diagrama ER em [`er.md`](./er.md).

## Consequências

- **Positivas:** operação mínima, backups automáticos (7 dias), credenciais fora do código, isolamento de rede (privado + SG restritivo), compatibilidade total com o app e com a Lambda.
- **Negativas / trade-offs:** single-AZ (sem failover automático — aceitável para o escopo do desafio); `deletion_protection = false` e `skip_final_snapshot = true` para permitir `destroy` limpo após a apresentação — **não usar assim em produção real**.
- **Custo:** dentro do Free Tier enquanto `db.t4g.micro` + 20 GB. Destruir após a apresentação.
