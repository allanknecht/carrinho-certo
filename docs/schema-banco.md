# Database schema – Carrinho Certo

## NFC-e discounts (research)

- **In NFC-e XML** there is per-item and total discount (`vDesc`). When the issuer enables “show discount on NFC-e”, it appears as separate tags.
- **On SEFAZ consultation HTML** we usually only see **prices after discount** (unit/total already reduced). A separate “discount” line is rare.
- **Conclusion:** For “best price” and alerts, **paid values** matter. `valor_unitario` / `valor_total` on `receipt_items_raw` reflect that. If XML is available later, optional `desconto_item` on `receipt_items_raw` can be added.

---

## Entity overview

```
users
  └── receipts (submitted notes; optional shopping_lists later)
        └── receipt_items_raw (raw lines + link to canonical product)

stores (per CNPJ)
  └── receipts
  └── observed_prices (optional FK)

products_canonical (rule-based normalization now; LLM later)
  └── product_aliases (raw-normalized label → canonical)
  └── receipt_items_raw (optional FK)
  └── observed_prices (one row per normalized line with prices)
```

---

## Implemented in Rails API (current)

The following match `backend/api/db/schema.rb` (includes `observed_prices`, migration `20260329180000`).

### `users`

| Column           | Type        | Notes                    |
|------------------|------------|--------------------------|
| id               | bigint PK  |                          |
| email            | string     | unique, required         |
| password_digest  | string     | `has_secure_password`    |
| created_at       | datetime   |                          |
| updated_at       | datetime   |                          |

### `stores`

| Column     | Type     | Notes              |
|-----------|----------|--------------------|
| id        | bigint PK|                    |
| cnpj      | string   | unique, 14 digits  |
| nome      | string   | required           |
| endereco  | text     | optional           |
| cidade    | string   | optional           |
| uf        | string(2)| optional           |
| created_at, updated_at | datetime |        |

### `receipts`

| Column           | Type        | Notes |
|------------------|------------|-------|
| id               | bigint PK  |       |
| user_id          | bigint FK  | required → users |
| store_id         | bigint FK  | optional → stores (set when parser finds emitente CNPJ) |
| source_url       | text       | consultation / QR URL |
| status           | string     | `queued`, `processing`, `done`, `failed` |
| processing_error | text       | set when `failed` |
| processed_at     | datetime   | when processing finished (success or failure) |
| chave_acesso     | string(44) | unique **partial** index where `chave_acesso IS NOT NULL`; often set from QR URL on `POST`, always reconciled from parsed NF-e when `done` |
| numero           | string     | note number (`nNF`), filled when parsing completes |
| serie            | string     | series |
| data_emissao     | date       |       |
| hora_emissao     | time       |       |
| valor_total      | decimal(12,2) | note total when parsed |
| created_at, updated_at | datetime |   |

**LGPD note:** future anonimization can set `user_id` to NULL while keeping `chave_acesso` for deduplication (see LGPD section below).

### `receipt_items_raw`

| Column                 | Type          | Notes |
|------------------------|---------------|-------|
| id                     | bigint PK     |       |
| receipt_id             | bigint FK     | required → receipts |
| descricao_bruta        | text          | required |
| codigo_estabelecimento | string        | PDV code when parsed |
| quantidade             | decimal(12,3) | optional |
| unidade                | string(10)    | optional |
| valor_unitario         | decimal(12,4)| optional (often filled from XML or SVRS-style HTML) |
| valor_total            | decimal(12,2)| optional |
| ordem                  | integer       | line order, default 0 |
| product_canonical_id   | bigint FK     | optional → `products_canonical` (filled by `NormalizeReceiptItemsJob` via `ProductNormalization::AssignCanonical`) |
| normalization_source   | string        | `alias`, `canonical_key`, `llm` (new or exact key match), `llm_merge` (second LLM pass linked line to existing catalog row), or `new_canonical` (heuristic) |
| created_at, updated_at | datetime      |       |

### `observed_prices`

One row per receipt line once it has a canonical product: values copied for aggregation (`GET /products/.../prices` later). **Unique** on `receipt_item_raw_id` so retries are idempotent. Not exposed as “user’s receipts”; internal link only.

| Column               | Type          | Notes |
|----------------------|---------------|--------|
| id                   | bigint PK     |       |
| product_canonical_id | bigint FK     | required → `products_canonical` |
| store_id             | bigint FK     | optional → `stores` (from receipt; null if CNPJ unknown) |
| receipt_item_raw_id  | bigint FK     | required → `receipt_items_raw`, **unique** |
| observed_on          | date          | `receipts.data_emissao`, else `processed_at` date, else today |
| quantidade           | decimal(12,3) | optional |
| valor_unitario       | decimal(12,4) | optional |
| valor_total          | decimal(12,2) | optional |
| created_at, updated_at | datetime      |       |

Written by `Pricing::RecordObservedPrice` at the end of `NormalizeReceiptItemsJob` (after normalization). If the job fails after assigning a canonical but before recording, a retry still records because the job walks all lines and skips only missing canonicals.

### `products_canonical`

| Column         | Type   | Notes |
|----------------|--------|--------|
| id             | bigint PK | |
| display_name   | string | human-facing label (defaults from raw line text) |
| normalized_key | string | unique, folded text for matching (see `ProductNormalization::TextNormalizer`) |
| created_at, updated_at | datetime | |

### `product_aliases`

| Column              | Type   | Notes |
|---------------------|--------|--------|
| id                  | bigint PK | |
| product_canonical_id| bigint FK | required → `products_canonical` |
| alias_normalized    | string | unique; same normalization as raw lines |
| source              | string | default `manual`; `llm` / `llm_merge` when created by normalization (merge = linked typo/variant to existing canonical) |

---

## Processing pipeline (reference)

1. Client `POST /receipts` with `source_url`.
2. Optional `409` if access key from URL already exists.
3. `ProcessReceiptJob` runs: HTTP GET → `NfceConsultationParser` (XML or HTML, including SVRS QrCode layout) → upsert `Store` by CNPJ → replace `receipt_items_raw` → update `receipts` to `done` or `failed` → enqueue `NormalizeReceiptItemsJob`.
4. `NormalizeReceiptItemsJob`: for each line, `AssignCanonical` if needed, then `Pricing::RecordObservedPrice` when `product_canonical_id` is set.

---

## Planned tables (not migrated yet)

The following describe **additional** targets for lists, alerts, and richer analytics (beyond `observed_prices`).

**Relevant price rule (MVP idea):** among `observed_prices` rows with **≥ 2 receipts** in the window, prefer the most recent; if none, use the latest single observation and label “based on 1 receipt”. See original product spec for mode, outliers, and UI copy.

### `shopping_lists`, `shopping_list_items`

User lists; items may reference `product_id` or free text.

### `price_alerts`, `price_outliers`

Future alerting and suspicious price flags.

---

## LGPD / account deletion

| Action | Reason |
|--------|--------|
| Delete `users` row | Removes login. |
| Delete user’s `shopping_lists` / items / `price_alerts` | Personal preferences. |
| `UPDATE receipts SET user_id = NULL` for that user | Detaches identity; keeps aggregate history. |
| Keep receipts (with NULL `user_id`), `receipt_items_raw`, `stores`, catalog/price tables | Needed for aggregated service. |

Do **not** remove `chave_acesso` from receipts: required for deduplication and integrity. Removing the **user link** is enough.

---

## Discounts – short answer

- **XML:** explicit discount fields exist.
- **HTML scrape:** usually only **post-discount** prices.
- **Use** `valor_unitario` / `valor_total` as paid amounts; extend schema if explicit discount is parsed later.

---

## App features vs schema (summary)

| Feature              | Schema area (current / planned)        |
|---------------------|----------------------------------------|
| Submit receipt URL  | `receipts`, job, parser                |
| Store / note header | `stores`, `receipts`                   |
| Raw lines + canonical | `receipt_items_raw`, `products_canonical`, `product_aliases` |
| Observed prices       | `observed_prices`                      |
| Product & price UI  | aggregate from `observed_prices` (HTTP API planned) |
| Shopping lists      | `shopping_lists` (planned)             |
| Where to buy        | derived from `prices` (planned)        |
