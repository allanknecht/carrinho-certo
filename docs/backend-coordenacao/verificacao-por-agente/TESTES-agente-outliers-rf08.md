# Verificação — Agente Outliers (RF08)

**Escopo:** resposta de `GET /products/:id/prices` inclui objeto `price_outlier` (`relevant_price_atypical_low`, `disclaimer`) e regra em `Pricing::PriceOutlierAssessment` / integração em `ProductPricesSummary`.  
**Não é da tua responsabilidade:** `GET /products` (index), listas, `store_rankings`, LGPD.

---

## Pré-requisitos

- Docker + API.
- Um `products_canonical.id` que tenha observações na janela de 30 dias para testar cenários com e sem flag (dados de teste ou documentação em `product_prices_summary_test`).

---

## 1. Testes automatizados (obrigatório)

```bash
bin/rails test test/services/pricing/product_prices_summary_test.rb
```

Esperado: **0 falhas** (inclui casos com e sem outlier, conforme o que estiver no ficheiro).

---

## 2. Smoke manual (opcional)

1. Obter `TOKEN` e um `PRODUCT_ID` válido.

2.:

```bash
curl -s "http://localhost:3000/products/PRODUCT_ID/prices" \
  -H "Authorization: Bearer TOKEN"
```

3. Confirmar no JSON raiz: chave `price_outlier` com estrutura esperada (boolean + `disclaimer` string ou null), alinhada a `docs/api-contrato.md`.

4. Se possível, comparar dois produtos: um onde o preço relevante seja “normal” e outro onde o teste automático já provou atipicidade — valida consistência.

---

## 3. Contrato

`docs/api-contrato.md` — secção de preços do produto (inclui `price_outlier`).

---

## Resultado da verificação *(opcional; só editar este ficheiro)*

| Data | Testes auto | Smoke manual | Notas |
|------|-------------|--------------|-------|
|      | OK / falha  | OK / N/A     |       |
