# Verificação — Agente RF10 (preços agregados por lista)

**Escopo:** `GET /shopping_lists/:id/store_rankings` e serviço `Pricing::ShoppingListStoreTotals`.  
**Não é da tua responsabilidade:** outliers (`price_outlier` no endpoint de preço de produto), catálogo isolado.

---

## Pré-requisitos

- Docker + API; migrações aplicadas.
- Pelo menos uma lista com itens que referenciem produtos com preços observáveis na janela de 30 dias (dados de teste ou seeds) — senão a resposta pode ser válida mas com lojas vazias.

---

## 1. Testes automatizados (obrigatório)

```bash
bin/rails test test/services/pricing/shopping_list_store_totals_test.rb test/controllers/shopping_lists_controller_test.rb
```

Esperado: **0 falhas** (ou falhas só se o ficheiro de teste do controller tiver exemplos partilhados — em caso de dúvida, corre também só o service test).

Se o projeto separar testes do controller por contexto, ajusta o path conforme existir em `test/`.

---

## 2. Smoke manual (opcional)

1. Token + `shopping_list_id` com itens (`product_canonical_id` + `quantidade`).

2.:

```bash
curl -s "http://localhost:3000/shopping_lists/LIST_ID/store_rankings" \
  -H "Authorization: Bearer TOKEN"
```

3. Confirmar: `200`, presença de `stores` (array), campos `estimated_total`, `lines_covered`, `lines_missing_price`, ordenação conforme `docs/api-contrato.md` (§ RF10 / store rankings).

4. `404` ou erro JSON coerente para lista inexistente ou de outro utilizador.

---

## 3. Contrato

`docs/api-contrato.md` — secção de ranking de lojas por lista.

---

## Resultado da verificação *(opcional; só editar este ficheiro)*

| Data | Testes auto | Smoke manual | Notas |
|------|-------------|--------------|-------|
|      | OK / falha  | OK / N/A     |       |
