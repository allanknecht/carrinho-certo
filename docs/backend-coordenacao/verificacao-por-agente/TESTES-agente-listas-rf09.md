# Verificação — Agente Listas (RF09)

**Escopo:** CRUD de `shopping_lists` e itens aninhados em `/shopping_lists/.../items`.  
**Não é da tua responsabilidade:** `GET /products/:id/prices`, `store_rankings`, outliers, `DELETE /account`.

---

## Pré-requisitos

- Docker + API a correr; comandos Rails no container (`COMUNICACAO.md` na pasta pai).
- Token de utilizador (login) para rotas autenticadas.

---

## 1. Testes automatizados (obrigatório)

```bash
bin/rails test test/controllers/shopping_lists_controller_test.rb test/controllers/shopping_list_items_controller_test.rb
```

Esperado: **0 falhas**.

---

## 2. Smoke manual (opcional)

1. Login e guardar `TOKEN`.

2. Criar lista:

```bash
curl -s -X POST http://localhost:3000/shopping_lists \
  -H "Authorization: Bearer TOKEN" -H "Content-Type: application/json" \
  -d "{\"name\":\"Teste QA\"}"
```

3. Adicionar item (substituir `SHOPPING_LIST_ID` e, se existir na BD, um `product_canonical_id` válido):

```bash
curl -s -X POST http://localhost:3000/shopping_lists/SHOPPING_LIST_ID/items \
  -H "Authorization: Bearer TOKEN" -H "Content-Type: application/json" \
  -d "{\"quantidade\":\"2\",\"label\":\"item manual\"}"
```

4. `GET /shopping_lists/SHOPPING_LIST_ID` — confirmar `items` e `items_count`.

5. `PATCH` item e `DELETE` item/lista conforme contrato em `docs/api-contrato.md` (secção de listas).

---

## 3. Contrato

`docs/api-contrato.md` — secção de shopping lists / itens.

---

## Resultado da verificação *(opcional; só editar este ficheiro)*

| Data | Testes auto | Smoke manual | Notas |
|------|-------------|--------------|-------|
|      | OK / falha  | OK / N/A     |       |
