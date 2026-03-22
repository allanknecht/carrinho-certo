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

Additional columns when done (see [schema-banco.md](schema-banco.md)): `chave_acesso`, `store_id`, line items in `receipt_items_raw`, etc.

### 2.3. Get receipt (not implemented yet)

Planned for the mobile client (polling):

- `GET /receipts/:id` — receipt header + `receipt_item_raws` + store, scoped to the current user.

Until this exists, the app can only rely on `POST` response and future polling endpoint.

---

## 3. Product prices (not implemented yet)

`GET /products/:id/prices?period=30`

Requires authentication. Response shape remains as originally sketched (product + stores + `relevant_price`, etc.). Depends on normalized `products` / `prices` tables.

---

## 4. Shopping lists & “where to buy” (skeleton)

Not implemented in the API yet; contract kept for roadmap.

- `POST /shopping_lists`
- `POST /shopping_lists/:id/items`
- `GET /shopping_lists/:id/suggestion`

---

## 5. Health

`GET /up`

**Response `200`**

```json
{
  "status": "ok"
}
```

---

## 6. Implementation notes

- **Duplicate access keys:** unique partial index on `receipts.chave_acesso` where not null; `409` when the key can be derived from `source_url` before insert; job also checks before save and handles `RecordNotUnique`.
- **Parser:** NF-e XML first; HTML fallback including SVRS `QrCodeNFce` table layout (two columns, `Código` / `Vl. Unit.` / `Vl. Total` in cell text).
- **Dev jobs:** `config.active_job.queue_adapter = :async` (in-process). **Tests:** `:test` adapter. Production should use a persistent backend (e.g. Solid Queue) when deploying.
