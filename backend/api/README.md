# Carrinho Certo API (Rails)

JSON API for receipt ingestion (NFC-e consultation URLs), authentication, and (planned) product prices.

## Docs

- **[API contract](../../docs/api-contrato.md)** — endpoints, auth, receipt flow, error codes.
- **[Database schema](../../docs/schema-banco.md)** — tables and processing pipeline.

## Local run (Docker)

From repo root:

```bash
docker compose up --build
```

API: `http://localhost:3000`. Set `DATABASE_URL` if running `bin/rails` outside Compose.

## Tests

```bash
cd backend/api
bundle install
bin/rails db:test:prepare
bin/rails test
```

Use `minitest` `~> 5.25` (see `Gemfile`) for Rails 8 test runner compatibility.

## Stack

- Rails 8, PostgreSQL, Active Job (`async` in development, `:test` in test env).
