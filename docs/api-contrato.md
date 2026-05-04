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

For each **store** that has any `observed_prices` row for this product, the API returns **one** row: the observation with the **latest** `observed_on` (NFC-e **issue date** on the receipt), then `updated_at` as a tie-breaker. There is **no** rolling date window and **no** minimum number of receipts per store.

`observed_on` in the JSON is that emission date (ISO 8601 **date**). Values are taken from `observed_prices` (no receipt or line ids in the response).

**Response `200`**

```json
{
  "product": {
    "id": 2,
    "display_name": "Sprite Lata 350 ml",
    "normalized_key": "SPRITE LATA 350 ML"
  },
  "stores": [
    {
      "store_id": 1,
      "nome": "MIX COMERCIO DE SOVETES LTDA ME",
      "cnpj": "26266835000181",
      "observed_on": "2026-03-29",
      "unit_price": "7.00",
      "unidade": "UN",
      "quantidade": "1",
      "line_total": "7.00",
      "receipt_total": "31.78"
    }
  ]
}
```

- **`stores`**: one object per distinct `store_id`; sorted by most recent **`observed_on`** (then `updated_at`) descending.
- **`unit_price`** / **`line_total`**: from the chosen observation; **`receipt_total`** is the whole receipt total for context (string with two decimals when present).

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

Returns stores that have at least one **latest** price observation for **any** list product, with **estimated_total** and per-store coverage. For each **store** and **product**, the unit price is taken from the same rule as **`GET /products/:id/prices`**: the observation with the greatest **`observed_on`** (receipt issue date), then **`updated_at`**, over **all** time (no rolling window, no minimum receipt count).

**Response `200`**

```json
{
  "shopping_list_id": 3,
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
- **`estimated_total`:** sum of *(unit price × list line `quantidade`)* for lines with a price at that store; two decimal places as a string.
- **`lines_covered`:** product lines priced at this store.
- **`lines_missing_price`:** `without_product` plus product lines without a usable price here.
- **`stores`:** sorted by **`estimated_total`** ascending, then **`store_id`**. Includes every store that has at least one observation for **some** list product (may still show **`estimated_total` `"0.00"`** if no line has a price at that store).

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
