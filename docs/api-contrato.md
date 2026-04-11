# API contract – Carrinho Certo (MVP)

Minimum contract for the Ruby on Rails API consumed by the mobile app (.NET MAUI). Use this as the reference for development and tests.

## General

- **Dev base URL:** `http://localhost:3000`
- **Format:** JSON (`Content-Type: application/json`)
- **Auth (MVP):** `Authorization: Bearer <token>` (token from login; `generates_token_for :api` on `User`)

---

## 1. Authentication

### 1.1. Sign up (MVP)

`POST /users`

**Request**

```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response `201`**

```json
{
  "id": 1,
  "email": "user@example.com"
}
```

### 1.2. Login

`POST /auth/login`

**Request**

```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response `200`**

```json
{
  "token": "opaque-signed-token",
  "user": {
    "id": 1,
    "email": "user@example.com"
  }
}
```

**Errors**

- `401` – invalid credentials

### 1.3. Account deletion (LGPD / RF11)

`DELETE /account`

Requires `Authorization: Bearer <token>`.

Permanently removes the authenticated **user** (email and credentials). **Shopping lists** and **list items** for that user are deleted. **Receipts** submitted by the user are **kept** for aggregate pricing: `receipts.user_id` is set to `null` (anonymous); `chave_acesso` and line data are **not** removed (see [schema-banco.md](schema-banco.md) — LGPD / account deletion).

**Response `204`**

- Empty body.

**Response `401`** — missing or invalid Bearer token.

---

## 2. Receipts (NFC-e QR / consultation URL)

Processing is **asynchronous**: `POST /receipts` enqueues `ProcessReceiptJob`, which fetches the URL, parses XML or HTML (`NfceConsultationParser`), persists `stores`, `receipts`, and `receipt_items_raw`, and sets receipt `status` to `done` or `failed`.

### 2.1. Submit receipt URL

`POST /receipts`

Requires `Authorization: Bearer <token>`.

**Request** — flat JSON at the root (no `receipt` wrapper):

```json
{
  "source_url": "https://dfe-portal.svrs.rs.gov.br/Dfe/QrCodeNFce?p=ACCESS_KEY|2|1|1|HASH"
}
```

**Access key & note number**

- If `source_url` yields a **44-digit access key** (`chave de acesso`), it is stored on the `receipts` row **as soon as the request is accepted** (`queued`). A **unique partial index** on `chave_acesso` blocks a second insert for the same key (including concurrent requests).
- **`numero`**, **`serie`**, and other header fields from the NF-e are read from the fetched document and saved when the job finishes (`done`).

**Response `202`**

```json
{
  "id": 123,
  "status": "queued",
  "message": "Receipt received and queued for processing."
}
```

**Errors**

- `400` – validation error (e.g. invalid URL)
- `401` – not authenticated
- `409 Conflict` – access key extracted from `source_url` already exists on another receipt:

```json
{
  "error": "Receipt already registered",
  "chave_acesso": "43260352932793000180650040000458781305092704"
}
```

### 2.2. Receipt lifecycle (`status`)

| Value        | Meaning                                      |
|-------------|-----------------------------------------------|
| `queued`    | Accepted; job not started or not yet picked up |
| `processing`| Job acquired the row and is fetching/parsing  |
| `done`      | Parsed and persisted successfully            |
| `failed`    | Error; see `processing_error` (if present)   |

Additional data when `done` (see [schema-banco.md](schema-banco.md)): `numero`, `serie`, dates, `valor_total`, `store_id`, line items in `receipt_items_raw`, etc. `chave_acesso` may already have been set at enqueue if it was parsed from the URL.

### 2.3. No receipt read API (by design)

The API does **not** expose `GET /receipts` or `GET /receipts/:id`. Users contribute NFC-e URLs to populate a **shared** dataset; the product experience is oriented toward **aggregate prices and suggestions** (e.g. `GET /products` and `GET /products/:id/prices`), not browsing one’s own submitted receipts.

The `202` response may still include `id` and `status` for acknowledgment only; clients should not rely on fetching that receipt later via the public API.

---

## 3. Product catalog (search / list)

`GET /products`

Requires `Authorization: Bearer <token>`.

Used to discover **`products_canonical.id`** before calling `GET /products/:id/prices`.

**Query parameters**

| Param | Default | Description |
|--------|---------|-------------|
| `q` | *(empty)* | Optional substring; matches **`display_name`** or **`normalized_key`** (case-insensitive, SQL `ILIKE`). |
| `page` | `1` | Page number (≥ 1). |
| `per` | `20` | Page size (1–100; values above 100 are capped at 100). |

**Response `200`**

```json
{
  "products": [
    {
      "id": 2,
      "display_name": "Sprite Lata 350 ml",
      "normalized_key": "SPRITE LATA 350 ML"
    }
  ],
  "meta": {
    "page": 1,
    "per": 20,
    "total": 42,
    "total_pages": 3
  }
}
```

- **`products`**: ordered by **`display_name`** ascending.
- **`meta.total_pages`**: `0` when **`total`** is `0`.

**Response `401`** — missing or invalid Bearer token.

---

## 4. Product prices

`GET /products/:id/prices`

Requires `Authorization: Bearer <token>`.

- **`:id`** — `products_canonical.id` (same catalog the app uses after normalization).

Only observations with `observed_on` in the **last 30 calendar days** (inclusive, ending today) are considered. Per store, prices are disclosed only when there are **at least two distinct NFC-e** (receipts) for that product **within that window**.

Observations come from `observed_prices` (no receipt or line ids in the response).

**Response `200`**

```json
{
  "product": {
    "id": 2,
    "display_name": "Sprite Lata 350 ml",
    "normalized_key": "SPRITE LATA 350 ML"
  },
  "period_days": 30,
  "window": { "from": "2026-02-27", "to": "2026-03-29" },
  "observations_count": 4,
  "receipts_distinct_count": 3,
  "prices_disclosed": true,
  "relevant_price": {
    "unit_price": "7.00",
    "unidade": "UN",
    "quantidade": "1",
    "line_total": "7.00",
    "receipt_total": "31.78",
    "observed_on": "2026-03-29",
    "store_id": 1,
    "basis": "latest_among_verified_stores"
  },
  "stores": [
    {
      "store_id": 1,
      "nome": "MIX COMERCIO DE SOVETES LTDA ME",
      "cnpj": "26266835000181",
      "observations_count": 3,
      "receipts_distinct_at_store": 3,
      "prices_disclosed": true,
      "last_observed_on": "2026-03-29",
      "recent_prices": [
        {
          "unit_price": "7.00",
          "unidade": "UN",
          "quantidade": "1",
          "line_total": "7.00",
          "receipt_total": "31.78",
          "observed_on": "2026-03-29"
        },
        {
          "unit_price": "65.90",
          "unidade": "KG",
          "quantidade": "0.376",
          "line_total": "24.78",
          "receipt_total": "31.78",
          "observed_on": "2026-03-28"
        },
        {
          "unit_price": "6.50",
          "unidade": "UN",
          "quantidade": "1",
          "line_total": "6.50",
          "receipt_total": "30.00",
          "observed_on": "2026-03-27"
        }
      ]
    }
  ]
}
```

- **`period_days`**: always **30** (fixed rolling window).
- **`receipts_distinct_count`**: distinct NFC-e receipts for this product in that window (**all stores**). A store can still hide prices until it has its own minimum (below).
- **`prices_disclosed`**: `true` if **at least one store** has **`receipts_distinct_at_store` ≥ 2** for this product **within the window** (prices are then shown for those stores only).
- **`relevant_price`**: latest observation among **only stores that meet the per-store minimum** (≥ 2 distinct receipts for this product at that store **in the window**). `null` if no store qualifies. **`basis`** is `latest_among_verified_stores`.
- **`stores`**: one row per `store_id` seen in the window.
  - **`receipts_distinct_at_store`**: how many different receipts at that store include this product **in the window**.
  - **`prices_disclosed`**: `true` only when **`receipts_distinct_at_store` ≥ 2**; then **`recent_prices`** has up to **3** entries (most recent first, then two older). If `false`, **`recent_prices`** is `[]` (no unit/total leaked for a lone receipt at that store).
  - **`observations_count`** / **`last_observed_on`**: all observations at that store, even when prices are hidden.

**Response `404`** — unknown product id:

```json
{ "error": "Product not found" }
```

**Response `401`** — missing or invalid Bearer token.

---

## 5. Shopping lists (RF09)

All routes below require `Authorization: Bearer <token>`. Lists and items are **scoped to the authenticated user**; `404` is returned when `:id` belongs to another user.

### 5.1 Lists CRUD

| Method | Path | Action |
|--------|------|--------|
| `GET` | `/shopping_lists` | List the user’s lists (newest `updated_at` first). |
| `POST` | `/shopping_lists` | Create a list. |
| `GET` | `/shopping_lists/:id` | Show one list with nested `items`. |
| `PATCH` / `PUT` | `/shopping_lists/:id` | Update `name`. |
| `DELETE` | `/shopping_lists/:id` | Delete list and all items. |

**Create — request**

```json
{ "name": "Compras da semana" }
```

**List response (`GET /shopping_lists`)**

```json
{
  "shopping_lists": [
    {
      "id": 1,
      "name": "Compras da semana",
      "items_count": 2,
      "created_at": "2026-04-11T12:00:00.000Z",
      "updated_at": "2026-04-11T12:00:00.000Z"
    }
  ]
}
```

**Single list (`GET` / `PATCH` response, `POST` `201`)** — includes nested `items`:

```json
{
  "id": 1,
  "name": "Compras da semana",
  "items_count": 2,
  "created_at": "2026-04-11T12:00:00.000Z",
  "updated_at": "2026-04-11T12:00:00.000Z",
  "items": [
    {
      "id": 10,
      "product_canonical_id": 2,
      "label": null,
      "quantidade": "2.000",
      "ordem": 0,
      "created_at": "2026-04-11T12:00:00.000Z",
      "updated_at": "2026-04-11T12:00:00.000Z"
    }
  ]
}
```

- **`quantidade`:** string decimal (scale 3), must be **> 0**.
- **`ordem`:** integer ≥ 0; ordering within the list is by `ordem` then `id`.

**Errors**

- `401` — missing or invalid token.
- `404` — list not found (including another user’s id).
- `422` — validation error (`errors` array of strings).

### 5.2 Items (nested under a list)

| Method | Path | Action |
|--------|------|--------|
| `GET` | `/shopping_lists/:shopping_list_id/items` | List items (ordered by `ordem`, then `id`). |
| `POST` | `/shopping_lists/:shopping_list_id/items` | Add an item. |
| `PATCH` / `PUT` | `/shopping_lists/:shopping_list_id/items/:id` | Update fields. |
| `DELETE` | `/shopping_lists/:shopping_list_id/items/:id` | Remove item. |

**Create / update — body** (flat JSON; on update, omitted keys keep previous values where applicable)

```json
{
  "product_canonical_id": 2,
  "label": "Item avulso",
  "quantidade": "1.500",
  "ordem": 0
}
```

- **`product_canonical_id`:** optional; must reference an existing `products_canonical.id` when set.
- **`label`:** optional free text (e.g. product not yet in the catalog).
- If **`ordem` is omitted** on create, the API assigns **max(existing `ordem`) + 1** (append to the end).

**Item-only JSON (`POST` `201`, `PATCH` `200`)** — same shape as each element of `items` above.

**`GET /shopping_lists/:shopping_list_id/items` — response `200`**

```json
{
  "items": [
    {
      "id": 10,
      "product_canonical_id": 2,
      "label": null,
      "quantidade": "2.000",
      "ordem": 0,
      "created_at": "2026-04-11T12:00:00.000Z",
      "updated_at": "2026-04-11T12:00:00.000Z"
    }
  ]
}
```

**Errors**

- `401` — unauthorized.
- `404` — shopping list not found, or item not in that list.
- `422` — validation (e.g. invalid `product_canonical_id`, `quantidade` ≤ 0).

### 5.3 Store rankings & estimated totals for a list (RF10)

`GET /shopping_lists/:id/store_rankings`

Returns stores observed for **any** product on the list within the price window, with **estimated_total** and per-store coverage. Pricing rules match **`GET /products/:id/prices`** (`ProductPricesSummary`):

- Only observations with **`observed_on`** in the **last 30 calendar days** (inclusive, ending today).
- For each **store** and **product**, a unit price counts only if that store has **≥ 2 distinct receipts** (NFC-e) for that product in that window.
- When the threshold is met, the **latest** observation (by `observed_on`, then `updated_at`) supplies the unit price (same derivation as product prices).

**Response `200`**

```json
{
  "shopping_list_id": 3,
  "period_days": 30,
  "window": { "from": "2026-03-12", "to": "2026-04-11" },
  "pricing_criteria": {
    "min_distinct_receipts_per_store_per_product": 2
  },
  "lines": {
    "total": 5,
    "with_product": 4,
    "without_product": 1
  },
  "stores": [
    {
      "store_id": 1,
      "nome": "MIX COMERCIO DE SOVETES LTDA ME",
      "cnpj": "26266835000181",
      "estimated_total": "42.50",
      "lines_covered": 3,
      "lines_missing_price": 2
    }
  ]
}
```

- **`lines.without_product`:** lines with no `product_canonical_id`; they count as **missing at every store**.
- **`estimated_total`:** sum of *(unit price × list line `quantidade`)* for lines with a disclosed price at that store; two decimal places as a string.
- **`lines_covered`:** product lines priced at this store in the window.
- **`lines_missing_price`:** `without_product` plus product lines without a usable price here.
- **`stores`:** sorted by **`estimated_total`** ascending, then **`store_id`**. Includes every store that has at least one observation in the window for **some** list product (may still show **`estimated_total` `"0.00"`** if no line meets the threshold).

**Response `404`** — list missing or not owned:

```json
{ "error": "Shopping list not found" }
```

**Response `401`** — missing or invalid Bearer token.

---

## 6. Health

`GET /up`

**Response `200`**

```json
{
  "status": "ok"
}
```

---

## 7. Implementation notes

- **Account deletion:** `DELETE /account` runs `User#destroy` with `receipts` associated as `dependent: :nullify` (nullable `receipts.user_id`); shopping lists use `dependent: :destroy`.
- **Duplicate access keys:** unique partial index on `receipts.chave_acesso` where not null; `409` when the key can be derived from `source_url` before insert; job also checks before save and handles `RecordNotUnique`.
- **Parser:** NF-e XML first; HTML fallback including SVRS `QrCodeNFce` table layout (two columns, `Código` / `Vl. Unit.` / `Vl. Total` in cell text).
- **Dev jobs:** `config.active_job.queue_adapter = :async` (in-process). **Tests:** `:test` adapter. Production should use a persistent backend (e.g. Solid Queue) when deploying.
- **Receipt visibility:** uploads are attributed to `user_id` for LGPD / moderation, but the HTTP API does not return per-user receipt lists or detail; value is in aggregated price data once normalization exists.
