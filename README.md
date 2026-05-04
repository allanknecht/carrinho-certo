# Carrinho Certo

Users scan the NFC-e QR code; the system ingests the receipt, normalizes products and prices, and suggests where to shop. Includes shopping lists, per-store pricing, and account deletion (LGPD).

## Repository layout

- **backend/** — Rails API + Active Job (`backend/api`): PostgreSQL, async receipt processing.
- **frontend/CarrinhoCerto/** — .NET MAUI app (UI; integrate with API per [docs/app-desenvolvimento.md](docs/app-desenvolvimento.md)).
- **docs/** — Schema, API contract, requirements (see [docs/README.md](docs/README.md)).

Details: [docs/estrutura-repositorio.md](docs/estrutura-repositorio.md).

## Quick start (API locally)

From the repo root (Docker Desktop running):

```bash
docker compose up -d
```

API base URL: **http://localhost:3000** — see [docs/app-desenvolvimento.md](docs/app-desenvolvimento.md) for emulators and the mobile app.

## Documentation

| Document | Content |
|----------|---------|
| [docs/app-desenvolvimento.md](docs/app-desenvolvimento.md) | **(PT)** Docker, rede, MAUI ↔ API. |
| [docs/frontend-guia-api-e-ordem.md](docs/frontend-guia-api-e-ordem.md) | **(PT)** Endpoints, JSON, ordem de implementação (equipa front). |
| [docs/estrutura-repositorio.md](docs/estrutura-repositorio.md) | Monorepo structure. |
| [docs/schema-banco.md](docs/schema-banco.md) | Tables, LGPD, pipeline. |
| [docs/api-contrato.md](docs/api-contrato.md) | **HTTP contract (English).** |
| [docs/objetivos-requisitos-casos-de-uso.md](docs/objetivos-requisitos-casos-de-uso.md) | Goals & requirements (PT). |
| [docs/telas-do-app.md](docs/telas-do-app.md) | Mobile screens (PT). |
| [docs/parecer-projeto-faculdade.md](docs/parecer-projeto-faculdade.md) | Academic / status notes. |

## Stack

- **Backend:** Ruby on Rails 8, PostgreSQL, Active Job.
- **App:** .NET MAUI (`frontend/CarrinhoCerto`).
