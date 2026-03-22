# Carrinho Certo

Users scan the NFC-e QR code; the system ingests the receipt, (eventually) normalizes products and prices, and suggests where to shop. Includes shopping lists, per-store pricing with history, and (planned) price alerts.

## Repository layout

- **backend/** — Rails API + Active Job (`backend/api`): receipts, auth, PostgreSQL.
- **app-mobile/** — .NET MAUI app: screens, QR scan, lists, “where to buy”.
- **docs/** — Database schema, API contract, requirements (see [docs/README.md](docs/README.md)).

Details: [docs/estrutura-repositorio.md](docs/estrutura-repositorio.md).

## Documentation

| Document | Content |
|----------|---------|
| [docs/estrutura-repositorio.md](docs/estrutura-repositorio.md) | Monorepo structure, Rails + jobs. |
| [docs/schema-banco.md](docs/schema-banco.md) | Tables (implemented + planned), LGPD, pipeline. |
| [docs/api-contrato.md](docs/api-contrato.md) | **API contract (English).** |
| [docs/objetivos-requisitos-casos-de-uso.md](docs/objetivos-requisitos-casos-de-uso.md) | Goals & requirements (PT). |
| [docs/telas-do-app.md](docs/telas-do-app.md) | Mobile screens (PT). |
| [docs/parecer-projeto-faculdade.md](docs/parecer-projeto-faculdade.md) | Doc status + implementation notes. |

## Stack

- **Backend:** Ruby on Rails 8, PostgreSQL, Active Job.
- **App:** .NET MAUI.
