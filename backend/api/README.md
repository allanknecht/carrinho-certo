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
