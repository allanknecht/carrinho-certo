# Repository structure – Carrinho Certo

Single monorepo: Ruby on Rails API, .NET MAUI app, and documentation.

## Layout

```
carrinho-certo/
├── backend/
│   └── api/              # Rails 8 API (JSON, PostgreSQL, Active Job)
├── frontend/
│   └── CarrinhoCerto/    # .NET MAUI client (screens, future HTTP integration)
├── docs/                 # Schema, API contract, requirements (mixed EN/PT)
├── docker-compose.yml    # PostgreSQL + API (development)
└── README.md
```

## Backend (Rails API)

- **HTTP API** — auth (`POST /users`, `POST /auth/login`, `DELETE /account`), receipt submission (`POST /receipts`), product catalog (`GET /products`), prices and outliers (`GET /products/:id/prices`), shopping lists and items, store rankings for a list (`GET /shopping_lists/:id/store_rankings`). There is no per-user receipt list/detail API by design (aggregate pricing focus).
- **Background work** — `ProcessReceiptJob` (Active Job): fetches NFC-e consultation URL, parses XML/HTML, writes `stores`, `receipts`, `receipt_items_raw`, normalization pipeline. In development, jobs use `queue_adapter = :async` inside the API process; production should use a persistent queue (e.g. Solid Queue).
- **Shared code** — models, services, and jobs live in the same Rails app (no separate worker repository).

## Mobile app

.NET MAUI under **`frontend/CarrinhoCerto/`**: UI shell; HTTP integration with the API is documented in **[app-desenvolvimento.md](app-desenvolvimento.md)** (Portuguese).

## Documentation

- **schema-banco.md** — implemented vs planned tables (English).
- **api-contrato.md** — HTTP contract (English).
- **app-desenvolvimento.md** — how to run Docker, connect the MAUI app, and use endpoints (Portuguese).
- **objetivos-…**, **telas-…**, **parecer-…** — Portuguese project briefs; cross-link to English technical docs.
