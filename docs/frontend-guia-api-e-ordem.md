# Guia para o front — API, respostas e ordem de implementação

Documento para a equipa do **.NET MAUI** (`frontend/CarrinhoCerto`): o que a API faz, o que cada endpoint devolve, e **uma ordem sugerida** de trabalho com exemplos de uso. Descreve o contrato **atual** da API para quem for implementar ou ligar o app; não pressupõe nada já feito no cliente.

- **Contrato detalhado (EN):** [api-contrato.md](api-contrato.md)  
- **Rede, emulador, Docker:** [app-desenvolvimento.md](app-desenvolvimento.md)

**Base URL (dev):** `http://localhost:3000` no PC; em emulador Android use `http://10.0.2.2:3000` (ver tabela no `app-desenvolvimento.md`).

---

## Autenticação em todos os endpoints protegidos

1. Obter `token` com `POST /auth/login` (ou registar com `POST /users` e depois login).
2. Em cada pedido seguinte enviar o cabeçalho:

```http
Authorization: Bearer <token>
Content-Type: application/json
```

3. Guardar o token de forma segura no dispositivo (Preferences / SecureStorage). Em `401`, limpar token e voltar ao ecrã de login.

---

## Lista completa de endpoints e respostas

Legenda: **Auth** = requer `Bearer` token.

### `GET /up`

| | |
|--|--|
| **Auth** | Não |
| **Resposta `200`** | JSON do health check do Rails (ex.: `{ "status": "ok" }` — ver resposta real no ambiente) |
| **Uso** | Verificar se a API está viva antes de mostrar o login ou a home |

---

### `POST /users` — registo

| | |
|--|--|
| **Auth** | Não |
| **Body** | `{ "email": "string", "password": "string" }` |
| **`201`** | `{ "id": <int>, "email": "<email>" }` |
| **`422`** | `{ "errors": ["mensagem", ...] }` |

---

### `POST /auth/login` — sessão

| | |
|--|--|
| **Auth** | Não |
| **Body** | `{ "email": "string", "password": "string" }` |
| **`200`** | `{ "token": "<jwt>", "user": { "id": <int>, "email": "..." } }` |
| **`401`** | `{ "error": "Invalid credentials" }` |

---

### `DELETE /account` — apagar conta (LGPD)

| | |
|--|--|
| **Auth** | Sim |
| **`204`** | Corpo vazio |
| **`401`** | Não autenticado |

Após sucesso, apagar token local e dados sensíveis da app.

---

### `POST /receipts` — enviar URL da NFC-e

| | |
|--|--|
| **Auth** | Sim |
| **Body** | `{ "source_url": "https://...QrCodeNFce?p=..." }` |
| **`202` Accepted** | `{ "id": <receipt_id>, "status": "queued", "message": "Receipt received and queued for processing." }` |
| **`409` Conflict** | `{ "error": "Receipt already registered", "chave_acesso": "44 dígitos..." }` — mesma nota já na base |
| **`400`** | `{ "errors": [...] }` se validação falhar |

**Nota UX:** o processamento é **assíncrono**. A API não devolve os itens da nota neste pedido. Mostrar mensagem do tipo “Nota recebida; os preços podem demorar alguns segundos a aparecer”. Opcionalmente, mais tarde, voltar a pedir `GET /products/:id/prices` ou refrescar listas depois de alguns segundos (não há endpoint de “estado da nota” para o utilizador na API atual).

---

### `GET /products` — catálogo (com pesquisa opcional)

| | |
|--|--|
| **Auth** | Sim |
| **Query** | `?q=texto` (opcional, pesquisa em `display_name` e `normalized_key`, case insensitive), `?page=1`, `?per=20` (máx. 100; default 20) |
| **`200`** | Ver JSON abaixo |

```json
{
  "products": [
    {
      "id": 1,
      "display_name": "Arroz demo 5kg",
      "normalized_key": "SEED_DEMO_ARROZ_5KG"
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

| **`401`** | `{ "error": "Unauthorized" }` |

---

### `GET /products/:id/prices` — preço por loja

| | |
|--|--|
| **Auth** | Sim |
| **`:id`** | `products_canonical.id` (o mesmo `id` que vem em `GET /products`) |
| **`200`** | Um objeto por **loja**: última observação pela **data de emissão** do cupom (`observed_on`), não pela data de upload |

```json
{
  "product": {
    "id": 7,
    "display_name": "Arroz demo 5kg",
    "normalized_key": "SEED_DEMO_ARROZ_5KG"
  },
  "stores": [
    {
      "store_id": 1,
      "nome": "Mercado …",
      "cnpj": "99000001000109",
      "observed_on": "2026-04-28",
      "unit_price": "10.00",
      "unidade": "UN",
      "quantidade": "2",
      "line_total": "20.00",
      "receipt_total": "50.00"
    }
  ]
}
```

- **`stores` vazio:** ainda não há `observed_prices` para esse produto (nota não processada ou linha sem produto canónico).
- A resposta traz só **`product`** e **`stores`** (estrutura do JSON acima). Se a UI precisar de um **único valor de destaque** (ex.: cartão na lista), definir no app como o derivar de `stores` (por exemplo menor `unit_price`, ou loja preferida).

| **`404`** | `{ "error": "Product not found" }` |

---

### `GET /shopping_lists` — listas do utilizador

| | |
|--|--|
| **Auth** | Sim |
| **`200`** | Itens **não** vêm nested (só contagens) |

```json
{
  "shopping_lists": [
    {
      "id": 1,
      "name": "Compras",
      "items_count": 3,
      "created_at": "2026-04-11T12:00:00.000Z",
      "updated_at": "2026-04-11T12:30:00.000Z"
    }
  ]
}
```

---

### `POST /shopping_lists` — criar lista

| | |
|--|--|
| **Auth** | Sim |
| **Body** | `{ "name": "Compras da semana" }` |
| **`201`** | Mesmo formato que `GET …/:id` com `items` (pode vir `items: []`) |
| **`422`** | `{ "errors": [...] }` |

---

### `GET /shopping_lists/:id` — detalhe com itens

| | |
|--|--|
| **Auth** | Sim |
| **`200`** | Inclui `items` ordenados por `ordem`, `id` |

```json
{
  "id": 1,
  "name": "Compras",
  "items_count": 2,
  "created_at": "...",
  "updated_at": "...",
  "items": [
    {
      "id": 10,
      "product_canonical_id": 7,
      "label": null,
      "quantidade": "2.000",
      "ordem": 0,
      "created_at": "...",
      "updated_at": "..."
    }
  ]
}
```

| **`404`** | `{ "error": "Shopping list not found" }` |

---

### `PATCH` ou `PUT /shopping_lists/:id` — renomear

| | |
|--|--|
| **Auth** | Sim |
| **Body** | `{ "name": "Novo nome" }` |
| **`200`** | Igual ao show (com `items`) |
| **`404` / `422`** | Como acima |

---

### `DELETE /shopping_lists/:id`

| | |
|--|--|
| **Auth** | Sim |
| **`204`** | Sem corpo |
| **`404`** | Lista não encontrada |

---

### `GET /shopping_lists/:id/items` — só itens

| | |
|--|--|
| **Auth** | Sim |
| **`200`** | `{ "items": [ ... mesmo formato de cada item ... ] }` |

---

### `POST /shopping_lists/:id/items` — adicionar linha

| | |
|--|--|
| **Auth** | Sim |
| **Body** | Campos permitidos: `product_canonical_id` (opcional), `label` (opcional), `quantidade` (obrigatório, > 0), `ordem` (opcional) |

Exemplos:

- Linha ligada a produto: `{ "product_canonical_id": 7, "quantidade": "2" }`
- Linha só texto: `{ "label": "Tomate", "quantidade": "1" }`

| **`201`** | Um objeto item (igual aos elementos de `items`) |
| **`404`** | `{ "error": "Shopping list not found" }` |
| **`422`** | `{ "errors": [...] }` |

---

### `PATCH` ou `PUT /shopping_lists/:id/items/:id` — editar linha

| | |
|--|--|
| **Auth** | Sim |
| **Body** | Qualquer subconjunto de `product_canonical_id`, `label`, `quantidade`, `ordem` |
| **`200`** | Objeto item atualizado |
| **`404`** | `{ "error": "Shopping list item not found" }` |

---

### `DELETE /shopping_lists/:id/items/:id`

| | |
|--|--|
| **Auth** | Sim |
| **`204`** | Sem corpo |

---

### `GET /shopping_lists/:id/store_rankings` — “onde comprar” (estimativa)

| | |
|--|--|
| **Auth** | Sim |
| **`200`** | Para cada loja que tenha preço em **algum** produto da lista, estima o total usando o **último preço conhecido** por (loja, produto), pela data de emissão |

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
      "nome": "Mercado …",
      "cnpj": "...",
      "estimated_total": "42.50",
      "lines_covered": 3,
      "lines_missing_price": 2
    }
  ]
}
```

- **`lines_missing_price`:** inclui linhas **só com `label`** (sem `product_canonical_id`) + linhas com produto sem preço nessa loja.
- **`stores` ordenados** por `estimated_total` ascendente (menor total primeiro).

| **`404`** | Lista inexistente ou de outro utilizador |

---

## Ordem sugerida de implementação no front

A ideia é **desbloquear login e rede primeiro**, depois **catálogo e preços**, depois **listas e ranking**, e por fim **notas e conta**.

### Fase 1 — Infra e sessão (fazer primeiro)

| Passo | O quê | Endpoints |
|-------|--------|-----------|
| 1.1 | Configurar URL base (dev/prod) e cleartext Android se preciso | — ([app-desenvolvimento.md](app-desenvolvimento.md)) |
| 1.2 | Health check antes do login | `GET /up` |
| 1.3 | Ecrã registo + login; guardar `token` | `POST /users`, `POST /auth/login` |
| 1.4 | Cliente HTTP com interceptor que injeta `Authorization: Bearer` | Todas as rotas abaixo exceto `/up`, `/users`, `/auth/login` |

**Porquê primeiro:** sem token estáveis e base URL correta, nada mais funciona em dispositivo real/emulador.

---

### Fase 2 — Produtos e preços (núcleo da app)

| Passo | O quê | Endpoints |
|-------|--------|-----------|
| 2.1 | Lista paginada + pesquisa (debounce no `q`) | `GET /products?q=...&page=&per=` |
| 2.2 | Detalhe de preços por loja; mostrar `observed_on` como “data do preço (cupom)” | `GET /products/:id/prices` |
| 2.3 | Se a UI precisar de um “preço em destaque” único, calcular no app a partir de `stores` (regra de produto: ex. menor preço ou loja preferida) | `GET /products/:id/prices` |

**Porquê antes das listas:** reutilizam os mesmos `product.id` e o mesmo modelo mental de preço por loja que o ranking usa por baixo.

---

### Fase 3 — Listas de compras

| Passo | O quê | Endpoints |
|-------|--------|-----------|
| 3.1 | Listar listas na home | `GET /shopping_lists` |
| 3.2 | Criar lista vazia | `POST /shopping_lists` |
| 3.3 | Ecrã detalhe: carregar lista com itens | `GET /shopping_lists/:id` |
| 3.4 | Adicionar item a partir do catálogo (`product_canonical_id` + `quantidade`) ou texto (`label`) | `POST /shopping_lists/:id/items` |
| 3.5 | Editar quantidade / ordem / produto | `PATCH .../items/:id` |
| 3.6 | Apagar item ou lista | `DELETE .../items/:id`, `DELETE /shopping_lists/:id` |

**Dica:** após alterar itens, se mostrarem totais na mesma vista, voltar a chamar `GET .../store_rankings` ou invalidar cache local.

---

### Fase 4 — “Onde comprar” (ranking)

| Passo | O quê | Endpoints |
|-------|--------|-----------|
| 4.1 | Botão ou separador “Onde comprar” na lista | `GET /shopping_lists/:id/store_rankings` |
| 4.2 | Explicar na UI que linhas só com **nome** não entram no total por preço (`lines.without_product` / `lines_missing_price`) | Mesmo JSON |

**Porquê depois das listas:** o ranking depende dos `product_canonical_id` e `quantidade` dos itens.

---

### Fase 5 — Notas (scan / URL)

| Passo | O quê | Endpoints |
|-------|--------|-----------|
| 5.1 | Formulário colar URL ou resultado de QR → `POST /receipts` | Ver corpos acima |
| 5.2 | Tratar `202` (sucesso enfileirado) vs `409` (duplicada) | Mensagens distintas |
| 5.3 | Opcional: após alguns segundos, refrescar preços dos produtos que o utilizador costuma ver | `GET /products/:id/prices` |

**Porquê mais tarde:** exige fluxo assíncrono e mensagens claras; não bloqueia Fases 2–4.

---

### Fase 6 — Conta

| Passo | O quê | Endpoints |
|-------|--------|-----------|
| 6.1 | Confirmação + `DELETE /account` | Ver acima |
| 6.2 | Limpar token e dados locais | — |

---

Para detalhe campo a campo e códigos HTTP, ver também [api-contrato.md](api-contrato.md) (inglês).
