# Contrato da API – Carrinho Certo (MVP)

Este documento descreve o **contrato mínimo** da API Ruby que o app mobile (.NET MAUI) vai consumir. A ideia é ter um ponto de referência simples para desenvolvimento e testes.

Formato geral:

- **Base URL (dev):** `http://localhost:3000`
- **Formato:** JSON (`Content-Type: application/json`)
- **Autenticação (MVP):** token simples via header `Authorization: Bearer <token>` (gerado no login)

---

## 1. Autenticação

### 1.1. Criar conta (MVP simplificado)

Pode ser opcional no primeiro momento; o foco do MVP é o login para vincular notas a um usuário.

`POST /users`

**Request (JSON)**

```json
{
  "email": "user@example.com",
  "password": "senha123"
}
```

**Response 201 (JSON)**

```json
{
  "id": 1,
  "email": "user@example.com"
}
```

---

### 1.2. Login

`POST /auth/login`

**Request (JSON)**

```json
{
  "email": "user@example.com",
  "password": "senha123"
}
```

**Response 200 (JSON)**

```json
{
  "token": "jwt-ou-token-simples",
  "user": {
    "id": 1,
    "email": "user@example.com"
  }
}
```

**Erros possíveis**

- `401` – credenciais inválidas

---

## 2. Envio de nota (QR/URL NFC-e)

### 2.1. Enviar nota para processamento

`POST /receipts`

Requer autenticação: header `Authorization: Bearer <token>`.

**Request (JSON)** — corpo **plano** no root (`source_url` direto no objeto JSON). Não usar envelope `receipt`.

```json
{
  "source_url": "https://dfe-portal.svrs.rs.gov.br/Dfe/QrCodeNFce?p=CHAVE|2|1|1|HASH"
}
```

**Response 202 (JSON)** – nota aceita e enfileirada para processamento

```json
{
  "id": 123,
  "status": "queued",
  "message": "Nota recebida e enfileirada para processamento."
}
```

**Erros possíveis**

- `400` – URL inválida
- `401` – não autenticado

---

## 3. Consultar preços por produto

### 3.1. Buscar preços de um produto por mercado

`GET /products/:id/prices`

Requer autenticação.

Parâmetros de query opcionais:

- `period` – período em dias (ex.: `7`, `30`), default `30`.

**Exemplo de request**

`GET /products/42/prices?period=30`

**Response 200 (JSON)**

```json
{
  "product": {
    "id": 42,
    "name": "ARROZ BRANCO TIPO 1 5KG"
  },
  "period_days": 30,
  "stores": [
    {
      "store_id": 1,
      "store_name": "Mercado A",
      "relevant_price": 12.90,
      "relevant_notes_count": 10,
      "last_observation_date": "2026-03-10",
      "recent_prices": [
        { "value": 12.90, "notes_count": 10, "last_date": "2026-03-10" },
        { "value": 13.50, "notes_count": 3,  "last_date": "2026-02-28" }
      ]
    }
  ]
}
```

---

## 4. Listas de compras e sugestão “onde comprar” (esqueleto)

Para o MVP, basta ter o contrato esboçado; a implementação pode vir depois.

### 4.1. Criar lista

`POST /shopping_lists`

**Request (JSON)**

```json
{
  "name": "Compras do mês"
}
```

**Response 201 (JSON)**

```json
{
  "id": 10,
  "name": "Compras do mês"
}
```

---

### 4.2. Adicionar item na lista

`POST /shopping_lists/:id/items`

**Request (JSON)** – MVP com produto já normalizado

```json
{
  "product_id": 42,
  "quantity": 2
}
```

**Response 201 (JSON)**

```json
{
  "id": 99,
  "product_id": 42,
  "quantity": 2
}
```

---

### 4.3. Sugestão “onde comprar”

`GET /shopping_lists/:id/suggestion`

**Response 200 (JSON)**

```json
{
  "list_id": 10,
  "best_store": {
    "store_id": 1,
    "store_name": "Mercado A",
    "total_value": 250.75
  },
  "alternatives": [
    {
      "store_id": 2,
      "store_name": "Mercado B",
      "total_value": 260.10
    }
  ]
}
```

---

## 5. Health check

Endpoint simples para ver se a API está de pé.

`GET /up`

**Response 200 (JSON)**

```json
{
  "status": "ok"
}
```

