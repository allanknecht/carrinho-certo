# Plano backend — trabalho paralelo (sem app/front)

Objetivo: entregar **listas de compras (RF09)**, **sugestão “onde comprar” por lista (RF10)**, **busca/listagem de produtos**, **outliers (RF08)** e **exclusão de conta LGPD (RF11)**, com mínimo conflito entre agentes.

**Escopo explícito:** apenas `backend/api`, `docs/` de contrato/schema quando necessário. **Não** alterar `frontend/` nem app mobile.

---

## Papéis

| Papel | Responsabilidade |
|--------|------------------|
| **Orquestrador** | Define ordem de merge, resolve sobreposição de arquivos, atualiza contratos neste doc (seções *Contrato*), aponta bloqueios. Não precisa implementar código; pode fazer commits só de doc/coordenação. |
| **Agente Listas (RF09)** | Modelo, migrations, CRUD autenticado de listas e itens. |
| **Agente Catálogo** | Endpoints de busca/listagem de `products_canonical` para o app obter `id` antes de `/prices`. |
| **Agente LGPD (RF11)** | Exclusão de conta + anonimização de `receipts` conforme `schema-banco.md`. |
| **Agente RF10 Preços** | Serviço que agrega totais/ranking por loja para uma lista; depende do modelo de lista existir. |
| **Agente Outliers (RF08)** | Regras + exposição de flags/disclaimer de preço atípico (coordena com quem mexe em `ProductPricesSummary`). |

---

## Dependências (quem espera quem)

```mermaid
flowchart LR
  subgraph fase1 [Fase 1 - paralelo]
    L[RF09 Listas]
    C[Catálogo]
    G[LGPD]
  end
  L --> R[RF10 Agregação]
  fase1 --> R
  R --> O[RF08 Outliers opcional depois]
```

- **Fase 1 (simultânea):** Listas, Catálogo e LGPD **não dependem** uns dos outros (rotas e tabelas diferentes).
- **RF10:** Idealmente começa quando **RF09** já estiver na branch principal ou quando o contrato de `shopping_list_items` estiver fixo neste documento (o agente RF10 pode usar factories alinhadas ao PR de listas).
- **RF08:** Convém **depois** de RF10 ou em branch separada: ambos podem tocar `app/services/pricing/`. Se precisar ser paralelo, dividir por arquivo (ex.: outliers em novo serviço, sem editar o mesmo trecho de `product_prices_summary.rb` no mesmo sprint).

---

## Divisão de arquivos (evitar conflito)

| Área | Preferência de “dono” no sprint |
|------|--------------------------------|
| `config/routes.rb` | Orquestrador **ou** um único commit agregando rotas no fim do dia; agentes adicionam trechos em comentários no STATUS e o orquestrador unifica se necessário. |
| `db/schema.rb` | Gerado por migrations; cada agente só roda migrate na sua feature. |
| `docs/api-contrato.md` | Cada agente adiciona **sua seção**; evitar reescrever o mesmo parágrafo. |
| `ProductPricesSummary` | Preferência: **um agente por vez** (RF10 ou Outliers). |

---

## Contrato mínimo (o orquestrador preenche/atualiza após alinhamento)

**Estado (orquestrador):** **Catálogo** fechado em `docs/api-contrato.md` (§3). **RF09** consolidado abaixo com base no código presente no repositório; o agente Listas deve confirmar no `STATUS-agente-listas.md` e alinhar `api-contrato.md` §4 (ainda marcada como skeleton nalgumas cópias). **RF10 / LGPD** seguem em evolução.

### Catálogo (busca / listagem) — fechado

- Contrato canónico: **`docs/api-contrato.md`** — secção **§3. Product catalog (search / list)**.
- `GET /products` com `Authorization: Bearer`, query `q`, `page`, `per`; corpo com `products[]` (`id`, `display_name`, `normalized_key`) e `meta` (`page`, `per`, `total`, `total_pages`).

### Lista / itens (RF09) — consolidado (implementação + payloads)

- **Modelo:** `ShoppingList` → `User`; `name` (string, default vazio). `ShoppingListItem` → `shopping_list`, `product_canonical` opcional; campos `label`, `quantidade` (decimal > 0), `ordem` (inteiro ≥ 0).
- **Rotas (nested):** `resources :shopping_lists` com `resources :items, controller: "shopping_list_items"` → índice/crud de itens sob `/shopping_lists/:shopping_list_id/items`.
- **Item JSON:** `id`, `product_canonical_id`, `label`, `quantidade` (string decimal), `ordem`, `created_at`, `updated_at` (ISO8601 ms).
- **Lista JSON:** `id`, `name`, `items_count`, `created_at`, `updated_at`; com itens incluídos: `items` (array no payload de `show` / `create` / `update` conforme controlador).

### RF10 — entrada/saída esperada

- **Entrada:** `shopping_list_id` (via rota) **ou** payload explícito com array `{ product_canonical_id, quantidade }` para testes.
- **Saída:** lista ordenada de lojas com `store_id`, `nome`, `cnpj`, `estimated_total` (string decimal), `lines_covered` / `lines_missing_price`, critérios iguais ao `ProductPricesSummary` (janela 30 dias, ≥2 notas por loja para incluir preço daquele produto naquela loja).

*(O orquestrador detalha tipos JSON de RF10 aqui quando o agente fechar o formato.)*

### RF08 (outliers) — nota de coordenação

- Serviço dedicado em `app/services/pricing/price_outlier_assessment.rb` (evitar editar o mesmo ficheiro que RF10 no mesmo sprint, salvo acordo).

---

## Fluxo simultâneo recomendado

1. **Dia/sprint 1 — três agentes em paralelo**
   - **Listas:** migrations + modelos + controller + testes.
   - **Catálogo:** `GET /products` com `q=` e paginação + testes.
   - **LGPD:** destroy account + testes de anonimização.

2. **Sprint 2 — um agente (RF10)**  
   - Implementa serviço + rota (ex. `GET` ou `POST` para “melhor loja” para `shopping_list_id`).  
   - Rebase na branch que já tem RF09.

3. **Sprint 3 — outliers (opcional)**  
   - Serviço novo ou extensão controlada de resposta JSON; testes.

O **orquestrador** marca em `STATUS-orquestrador.md` qual branch base cada um deve usar (`main` / `backend`) e quando fazer merge.

---

## Critérios de pronto

- Testes automatizados (`bin/rails test`) passando com `DATABASE_URL` apontando para `api_test` quando usar Docker (ver nota no `backend/api/README.md` se existir).
- `api-contrato.md` atualizado para cada endpoint novo.
- Arquivo `STATUS-agente-*.md` preenchido com “Concluído” e lista de arquivos tocados.

---

## Após concluir o projeto backend

- Atualizar `docs/schema-banco.md` e `docs/parecer-projeto-faculdade.md` (status de implementação).
- Opcional: OpenAPI.
