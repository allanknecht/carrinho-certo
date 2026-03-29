# Repository structure – Carrinho Certo

Single monorepo: Ruby on Rails API, .NET MAUI app, and documentation.

## Layout

```
carrinho-certo/
├── backend/
│   └── api/              # Rails 8 API (JSON, PostgreSQL, Active Job)
├── app-mobile/           # .NET MAUI client
├── docs/                 # Schema, API contract, requirements (mixed EN/PT)
└── README.md
```

## Backend (Rails API)

- **HTTP API** — endpoints for auth, receipt submission (`POST /receipts` only; no per-user receipt browsing), and (planned) aggregate products/prices, lists.
- **Background work** — `ProcessReceiptJob` (Active Job): fetches NFC-e consultation URL, parses XML/HTML (`app/services/nfce_consultation_parser.rb`), writes `stores`, `receipts`, `receipt_items_raw`, then `ProductNormalization::AssignCanonical` links lines to `products_canonical` / `product_aliases` (rule-based; LLM later).
- **Shared code** — models, services, and jobs live in the same Rails app (no separate worker repository). In development, jobs use `queue_adapter = :async`; production should use a persistent queue (e.g. Solid Queue).

## Mobile app

.NET MAUI: UI, QR scan, HTTP calls to the API. Not part of the backend codebase.

## Documentation

- **schema-banco.md** — implemented vs planned tables (English).
- **api-contrato.md** — HTTP contract (English).
- **objetivos-…**, **telas-…**, **parecer-…** — Portuguese project briefs; cross-link to English technical docs.
