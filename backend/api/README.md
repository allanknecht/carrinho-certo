# Carrinho Certo API (Rails)

JSON API for receipt ingestion (NFC-e consultation URLs), authentication, and **`GET /products/:id/prices`** (aggregated from `observed_prices`).

## Docs

- **[API contract](../../docs/api-contrato.md)** — endpoints, auth, receipt flow, error codes.
- **[Database schema](../../docs/schema-banco.md)** — tables and processing pipeline.
- **[App development (PT)](../../docs/app-desenvolvimento.md)** — Docker, connecting the MAUI client, using endpoints from the app.

## Local run (Docker)

From repo root:

```bash
docker compose up --build
```

API: `http://localhost:3000`. Set `DATABASE_URL` if running `bin/rails` outside Compose.

## Demo data (`db:seed`)

In **development**, `bin/rails db:seed` loads **`Seeds::PricingDemo`** (`db/seeds/pricing_demo.rb`): três lojas (1 nota, 2 notas, 3 notas), dois produtos, preços e quantidades variados — para exercitar `GET /products/:id/prices` (incluindo loja com **só 1 NFC-e** = sem preço).

- **Pular:** `SKIP_PRICING_DEMO_SEEDS=1 bin/rails db:seed`
- **Forçar em outro ambiente:** `SEED_PRICING_DEMO=1 bin/rails db:seed`
- **Manual:** `bin/rails runner "Seeds::PricingDemo.run!(force: true)"`

Credenciais e ids são impressos no console. Testes: `bin/rails test test/integration/product_prices_demo_seeds_test.rb`.

## Product normalization + local LLM (Ollama)

Rule-based matching runs always (aliases + exact `normalized_key`). For **new** lines, you can send the description to a **local OpenAI-compatible** server (Ollama exposes `POST /v1/chat/completions`).

1. Run Ollama and pull a model, e.g. `ollama pull llama3.2`
2. Set environment variables for the API process:

| Variable | Example | Meaning |
|----------|---------|---------|
| `PRODUCT_NORMALIZATION_LLM_ENABLED` | `true` | Turn on LLM for unseen products |
| `OLLAMA_OPENAI_BASE_URL` | `http://localhost:11434/v1` | OpenAI-compatible base (no trailing slash required) |
| `OLLAMA_MODEL` | `llama3.2` | Model name in Ollama |
| `OLLAMA_API_KEY` | `ollama` | Sent as `Authorization: Bearer`; Ollama usually ignores it |
| `OLLAMA_READ_TIMEOUT` | `90` | Seconds (local models can be slow) |

If the LLM call errors or times out, the job **falls back** to the heuristic (same as before LLM). The first successful LLM mapping stores a `product_aliases` row (`source` `llm` or `llm_merge`) so identical POS text skips further model calls.

**Two-step LLM (when enabled):** (1) propose `normalized_key` + `display_name` from the line; (2) if the catalog has **candidate** rows (token overlap + recent items), a second prompt asks the model to **merge** with one of those ids or create **new** — merges only count if the id was in the candidate list (no hallucinated ids).

### Docker Compose (API no container, Ollama no PC)

From the repo root, `docker-compose.yml` passes through env vars. Create a `.env` next to it (or export in the shell) **before** `docker compose up`:

```bash
PRODUCT_NORMALIZATION_LLM_ENABLED=true
OLLAMA_OPENAI_BASE_URL=http://host.docker.internal:11434/v1
OLLAMA_MODEL=nome-exato-do-seu-modelo
```

Use `ollama list` on the host to copy the **exact** model tag (e.g. `llama3.2`, `qwen2.5:7b`). Inside the container, `localhost` is **not** your Windows Ollama — use `host.docker.internal` (Docker Desktop on Windows/Mac).

### Parece “travado” depois de importar a nota?

Com `PRODUCT_NORMALIZATION_LLM_ENABLED=true`, o `NormalizeReceiptItemsJob` pode ficar **vários segundos ou minutos** em cada linha à espera do Ollama (`OLLAMA_READ_TIMEOUT`, até ~120s no Compose). Enquanto isso o recibo já pode estar `done`, mas a normalização ainda corre em background. Confira `log/development.log` por `[ProcessReceiptJob]` e `[NormalizeReceiptItemsJob]`.

Para testar só parser + heurística sem LLM: `PRODUCT_NORMALIZATION_LLM_ENABLED=false` ou rode `bin/rails runner script/process_nfce_url_dev.rb '<url>'` (o script desliga a LLM por padrão; use `SMOKE_KEEP_LLM=1` se quiser manter).

## Dev helper scripts (`script/`)

Run from the **repo root** with the API container up (`docker compose up -d`). Commands assume service name `api` as in this project’s `docker-compose.yml`.

### `script/fetch_nfce_smoke.rb`

Fetches the consultation URL over HTTP and prints parser output (**no database writes**). Good for checking SVRS/HTML vs XML before touching the DB.

```bash
docker compose exec -T api bin/rails runner script/fetch_nfce_smoke.rb 'https://dfe-portal.svrs.rs.gov.br/Dfe/QrCodeNFce?p=CHAVE|2|1|1|HASH'
```

### `script/process_nfce_url_dev.rb`

End-to-end smoke on the **development** database: ensures a `User` exists, creates a `Receipt` (`queued`), runs `ProcessReceiptJob` and (with `:inline` adapter) `NormalizeReceiptItemsJob`, then prints line counts and `observed_prices`.

- **Duplicate NFC-e:** if the 44-digit key is already stored, the script **exits with code 1** (same idea as `409` from `POST /receipts`). Clear the DB or delete that receipt before re-testing the same URL.
- **LLM:** by default the script **turns LLM off** for a fast run. To use Ollama for this invocation:

```bash
docker compose exec -T \
  -e PRODUCT_NORMALIZATION_LLM_ENABLED=true \
  -e SMOKE_KEEP_LLM=1 \
  api bin/rails runner script/process_nfce_url_dev.rb 'https://...QrCodeNFce?p=...'
```

- **Heuristic only** (no extra `-e` flags): omit `PRODUCT_NORMALIZATION_LLM_ENABLED` / `SMOKE_KEEP_LLM` and run with the URL in **single quotes** (important on PowerShell because of `|` in the query string).

### `script/show_normalized_lines.rb`

Prints every stored line as: `descricao_bruta -> product_canonical.display_name (normalization_source)`.

- The **`display_name`** part is what you’d show in the app UI.
- **`(llm)` / `new_canonical` / etc.** are internal `normalization_source` values for debugging — **not** user-facing copy.

```bash
docker compose exec -T api bin/rails runner script/show_normalized_lines.rb
```

### Product prices API (`GET /products/:id/prices`)

See **[API contract](../../docs/api-contrato.md) §3** for the JSON shape. `:id` is **`products_canonical.id`** (use `show_normalized_lines` or the DB to pick an id after importing a note).

**Rails-only (no HTTP server required)** — prints the same payload the controller would return:

```bash
docker compose exec -T api bin/rails runner script/product_prices_smoke.rb 1
docker compose exec -T api bin/rails runner script/product_prices_smoke.rb 1 14
```

**HTTP smoke** (Rails server must be listening inside the same container on port 3000, e.g. `docker compose up`):

```bash
docker compose exec -T -e API_EMAIL=you@example.com -e API_PASSWORD=yourpassword \
  api bin/rails runner script/http_product_prices_smoke.rb 1
```

**curl** (from the host, with a token from `POST /auth/login`):

```bash
curl -sS -H "Authorization: Bearer YOUR_TOKEN" "http://localhost:3000/products/1/prices"
```

### Reset development DB (clean slate)

Drops and recreates `api_development` from `db/schema.rb` (all tables, indexes, FKs).

```bash
docker compose stop api
docker compose run --rm api bin/rails db:reset
docker compose up -d
```

**PowerShell:** prefer **single-quoted** URLs when passing them to `docker compose exec` so `|` and JSON-style escaping don’t break. For multi-line commands, end each line with the PowerShell continuation backtick (see the `process_nfce_url_dev` example above).

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
