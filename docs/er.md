# Diagrama ER — Oficina Mecânica

Modelo relacional da aplicação (PostgreSQL 16 no RDS), extraído das migrations do monorepo. Apenas tabelas de domínio (tabelas de framework — `cache`, `jobs`, `sessions`, `password_reset_tokens`, `personal_access_tokens`, `migrations` — foram omitidas).

> **Notas importantes**
> - `customers.document` guarda **CPF (11) ou CNPJ (14)**, só dígitos, `unique`. **Não há coluna `cpf`.** A autenticação por CPF (repo 1) consulta por `document`.
> - Não existe coluna `status`/`ativo` em `customers`: "inativo" = **soft delete** (`deleted_at`).
> - As colunas `status` (`order_services`, `part_requests`) são **strings** com valores definidos por enums PHP, não enums de banco.

```mermaid
erDiagram
    customers ||--o{ vehicles : "customer_id"
    customers ||--o{ order_services : "customer_id"
    vehicles  ||--o{ order_services : "vehicle_id"
    users     ||--o{ order_services : "mechanic_user_id"
    users     ||--o{ part_requests : "requested_by_user_id"
    order_services ||--o{ part_requests : "os_id (nullable)"
    order_services ||--|| budgets : "os_id (1:1)"
    order_services ||--o{ os_service_items : "os_id"
    order_services ||--o{ os_part_items : "os_id"
    order_services ||--o{ os_requested_service_items : "os_id"
    order_services ||--o{ os_requested_part_items : "os_id"
    services  ||--o{ os_service_items : "service_id"
    services  ||--o{ os_requested_service_items : "service_id"
    parts     ||--o{ os_part_items : "part_id"
    parts     ||--o{ os_requested_part_items : "part_id"
    part_requests ||--o{ part_request_items : "part_request_id"
    parts     ||--o{ part_request_items : "part_id"

    customers {
        bigint id PK
        string name
        string document UK "CPF/CNPJ, só dígitos"
        string email UK
        string phone
        string address
        timestamp deleted_at "soft delete = inativo"
    }
    vehicles {
        bigint id PK
        bigint customer_id FK
        string plate UK
        string brand
        string model
        smallint year
        string color
        timestamp deleted_at
    }
    users {
        bigint id PK
        string name
        string email UK
        string role "admin|attendant|mechanic|storekeeper|purchasing"
        string password
    }
    parts {
        bigint id PK
        string code UK "SKU"
        string name
        text description
        decimal unit_price
        int stock_quantity
        int minimum_stock
        string unit
        timestamp deleted_at
    }
    services {
        bigint id PK
        string name
        text description
        decimal base_price
        smallint estimated_minutes
        boolean is_active
        timestamp deleted_at
    }
    order_services {
        bigint id PK
        string status "OsStatus (created..delivered_and_finalized)"
        bigint customer_id FK
        bigint vehicle_id FK
        text complaint
        bigint mechanic_user_id FK "nullable"
        timestamp started_at
        timestamp finished_at
        timestamp deleted_at
    }
    budgets {
        bigint id PK
        bigint os_id FK "unique 1:1"
        decimal total_services
        decimal total_parts
        decimal total_amount
        text notes
    }
    os_service_items {
        bigint id PK
        bigint os_id FK
        bigint service_id FK
        string service_name
        int quantity
        decimal unit_price
    }
    os_part_items {
        bigint id PK
        bigint os_id FK
        bigint part_id FK
        string part_name
        int quantity
        decimal unit_price
    }
    os_requested_service_items {
        bigint id PK
        bigint os_id FK
        bigint service_id FK
        string service_name
        int quantity
    }
    os_requested_part_items {
        bigint id PK
        bigint os_id FK
        bigint part_id FK
        string part_name
        int quantity
    }
    part_requests {
        bigint id PK
        string status "PartRequestStatus (received..finalized)"
        bigint requested_by_user_id FK
        bigint os_id FK "nullable"
        text notes
    }
    part_request_items {
        bigint id PK
        bigint part_request_id FK
        bigint part_id FK
        string part_name
        int quantity_requested
        int quantity_provided
    }
```

## Ciclo de vida da OS (`order_services.status`)

Valores persistidos (enum `OsStatus`): `created` → `in_analysis` → `pending_approval` → (`in_renegotiation`) → `approved`/`rejected` → `in_execution` → `execution_finished` → `delivered_and_finalized`.

Existe um vocabulário público derivado (`PublicOsStatus`: recebida, diagnóstico, aguardando aprovação, execução, finalizada, entregue) usado nos dashboards de negócio (tempo médio por status), **não persistido** no banco.
