# Esquema do banco – Carrinho Certo

## Desconto na NFC-e (pesquisa)

- **No XML da NFC-e** existe o campo `vDesc` (valor de desconto) por item e no total. Quando o emissor configura “destacar desconto na NFC-e”, esse valor aparece como TAG separada.
- **Na prática, no HTML que a gente raspa** (página de consulta SEFAZ), o que aparece é quase sempre **só o preço já com desconto**: valor unitário e total já vêm reduzidos. Não costuma vir linha ou campo separado de “desconto” na tela.
- **Conclusão:** Para “melhor preço” e “alerta de preço”, o que importa é o **valor pago** (já descontado). O que estamos extraindo (valor_unitario e valor_total por item) é isso. Se no futuro você tiver acesso ao XML (ex.: API), dá para guardar `desconto_item` à parte; no esquema abaixo dá para adicionar uma coluna `desconto_item` em `receipt_items_raw` se um dia o parser passar a preencher.

---

## Visão geral das entidades

```
users
  └── shopping_lists
        └── shopping_list_items (product_id ou descricao_bruta)

stores (mercados)
  └── receipts (notas enviadas por usuários)
        └── receipt_items_raw (itens brutos da nota)

products_canonical (catálogo normalizado)
  └── product_aliases (descrições brutas → produto canônico)
  └── prices (produto + mercado + data + valor)
  └── price_alerts (futuro: alertas de preço)
  └── price_outliers (preços sinalizados como suspeitos)
```

---

## Tabelas

### 1. users
Usuários do app (login, lista de compras, alertas).

| Coluna      | Tipo         | Descrição                |
|-------------|--------------|--------------------------|
| id          | UUID / BIGSERIAL | PK                   |
| email       | VARCHAR(255) | único, login             |
| created_at  | TIMESTAMPTZ  |                          |

---

### 2. stores
Cadastro de mercados (um por CNPJ).

| Coluna      | Tipo         | Descrição                |
|-------------|--------------|--------------------------|
| id          | BIGSERIAL    | PK                       |
| cnpj        | VARCHAR(14)  | único, só dígitos        |
| nome        | VARCHAR(255) | ex.: "QC RS ERECHIM"    |
| endereco    | TEXT         | endereço completo        |
| cidade      | VARCHAR(100) | ex.: "ERECHIM"          |
| uf          | CHAR(2)      | ex.: "RS"                |
| created_at  | TIMESTAMPTZ  |                          |
| updated_at  | TIMESTAMPTZ  |                          |

---

### 3. receipts
Uma nota fiscal por linha (chave única).

| Coluna        | Tipo         | Descrição                |
|---------------|--------------|--------------------------|
| id            | BIGSERIAL    | PK                       |
| user_id       | BIGINT       | FK users (quem enviou)   |
| store_id      | BIGINT       | FK stores                |
| chave_acesso  | VARCHAR(44)  | único                    |
| numero        | VARCHAR(20)  | número da nota           |
| serie         | VARCHAR(10)  | série                    |
| data_emissao  | DATE         | data da nota             |
| hora_emissao  | TIME         | opcional                 |
| valor_total   | NUMERIC(12,2)| total pago               |
| source_url    | TEXT         | URL de consulta          |
| created_at    | TIMESTAMPTZ  |                          |

---

### 4. receipt_items_raw
Itens brutos da nota (antes de normalizar). O preço aqui já é o valor pago (com desconto embutido, quando for o caso).

| Coluna               | Tipo          | Descrição                |
|----------------------|---------------|--------------------------|
| id                   | BIGSERIAL     | PK                       |
| receipt_id            | BIGINT        | FK receipts              |
| descricao_bruta       | TEXT          | texto da nota            |
| codigo_estabelecimento| VARCHAR(50)   | código no PDV            |
| quantidade            | NUMERIC(12,3) |                          |
| unidade               | VARCHAR(10)   | UN, KG, L, etc. (se tiver) |
| valor_unitario        | NUMERIC(12,4) | preço unitário pago      |
| valor_total           | NUMERIC(12,2) | total do item            |
| ordem                 | INT           | ordem na nota            |
| created_at            | TIMESTAMPTZ   |                          |

*(Opcional para o futuro: `desconto_item NUMERIC(12,2)` se passar a vir do XML/portal.)*

---

### 5. products_canonical
Catálogo normalizado (saída da normalização + LLM/regras).

| Coluna         | Tipo          | Descrição                |
|----------------|---------------|--------------------------|
| id             | BIGSERIAL     | PK                       |
| nome_canonico  | VARCHAR(255) | ex.: "ARROZ BRANCO TIPO 1 5KG" |
| marca          | VARCHAR(100) | opcional                 |
| categoria      | VARCHAR(100)  | ex.: "mercearia"         |
| subcategoria   | VARCHAR(100)  | ex.: "arroz"            |
| unidade_padrao | VARCHAR(10)  | KG, L, UN, etc.          |
| created_at     | TIMESTAMPTZ   |                          |
| updated_at     | TIMESTAMPTZ   |                          |

---

### 6. product_aliases
Mapeamento “descrição bruta” → produto canônico (aprende com o uso).

| Coluna      | Tipo          | Descrição                |
|-------------|---------------|--------------------------|
| id          | BIGSERIAL     | PK                       |
| product_id  | BIGINT        | FK products_canonical   |
| alias_text  | VARCHAR(500)  | texto normalizado        |
| confidence  | NUMERIC(3,2)   | 0–1                      |
| source      | VARCHAR(20)   | 'rule' / 'llm' / 'manual' |
| approved_at | TIMESTAMPTZ   | NULL = pendente          |
| created_at  | TIMESTAMPTZ   |                          |

Índice único ou único parcial em `(alias_text, product_id)` para evitar duplicar mapeamento.

---

### 7. prices
Cada linha = uma observação de preço (produto + mercado + data). Serve para “preço em cada mercado” e para detecção de outlier.

| Coluna          | Tipo          | Descrição                |
|-----------------|---------------|--------------------------|
| id              | BIGSERIAL     | PK                       |
| product_id      | BIGINT        | FK products_canonical    |
| store_id        | BIGINT        | FK stores                |
| receipt_id      | BIGINT        | FK receipts (auditoria)  |
| receipt_item_id | BIGINT        | FK receipt_items_raw     |
| valor_unitario  | NUMERIC(12,4) | preço unitário           |
| quantidade      | NUMERIC(12,3) | qtd do item              |
| valor_total     | NUMERIC(12,2) | total do item            |
| data_referencia | DATE          | data da nota             |
| created_at      | TIMESTAMPTZ   |                          |

Índices úteis: `(product_id, store_id, data_referencia)`, `(product_id, data_referencia)`.

- **“Preço em cada mercado”:** para um `product_id`, buscar por store (ex.: último preço por loja ou média recente).
- **“Onde é melhor comprar”:** somar, por lista, o custo por mercado e escolher o menor (ou lógica de distância + preço).
- **Outlier:** comparar cada preço com a distribuição (ex.: mediana) do mesmo produto em outros mercados/datas.

#### Histórico de preços e o que mostrar na lista (1 ou 2 preços por mercado)

- **Sim, guardamos histórico:** cada nota normalizada gera novas linhas em `prices`; não apagamos as antigas. Os preços exibidos aos clientes são **sempre** os que já passaram pela normalização.
- **Na lista do item, por mercado:** mostramos **1 preço atual** (usado em "onde é melhor comprar") + **1 ou 2 preços anteriores** (últimos registrados).

**Regra sugerida (MVP):**

| Conceito | Regra |
|----------|--------|
| **Preço relevante** | Entre os valores com **≥ 2 notas** no período (ex.: 30 dias), usar o **mais recente**. Se não houver nenhum com ≥2 notas, usar o mais recente e sinalizar "baseado em 1 nota". (Detalhe na seção abaixo.) |
| **Últimos preços (exibir)** | Últimas 2–5 linhas para (product_id, store_id), ordenadas por `data_referencia DESC`. Na UI: "relevante" + "1 ou 2 anteriores" por mercado. |

Exemplo na tela: **Mercado A:** R$ 12,90 (relevante, 10 notas) · R$ 8,90 em 1 nota (possível promo — ver alerta).

**Quando "atualizar":** Sempre que uma nota é normalizada, inserimos novas linhas em `prices`. O "preço relevante" (usado na sugestão e como principal na tela) segue a regra abaixo; o alerta de preço muito abaixo do normal continua valendo (ver seção price_outliers).

#### Preço "relevante": pelo menos 2 notas com o mesmo valor

Um único preço com puta desconto (1 nota) pode ser desconto só daquela pessoa; 10 notas de 5 min atrás com o mesmo valor são mais representativas do que o cliente vai encontrar. Por isso:

**Regra do preço relevante (para "onde comprar" e destaque na tela):**

| Situação | O que usar como preço principal |
|----------|----------------------------------|
| Existe algum valor com **≥ 2 notas** no período (ex.: últimos 30 dias)? | Entre esses, usar o **mais recente** (maior `data_referencia`). Esse é o preço "relevante". |
| **Nenhum** valor tem ≥ 2 notas? | Usar o **mais recente** (1 nota) e na UI sinalizar: "Baseado em 1 nota — pode variar". |

Assim: 10 notas com R$ 12,90 (última há 5 min) + 1 nota com R$ 8,90 (desconto) → o **relevante** é R$ 12,90 (tem ≥2 notas e é o mais recente entre os que têm ≥2). O R$ 8,90 continua aparecendo na lista de preços do período, com o **alerta de preço muito abaixo** (cor diferente + disclaimer "pode ser promoção ou desconto pontual"), mas não vira o preço principal daquele mercado.

**Resumo:** Priorizar sempre o valor que tenha **pelo menos 2 notas com valor igual** no período, preferindo o mais recente entre esses. Só usar "último de 1 nota" quando não houver nenhum valor com ≥2 notas. O alerta de preço muito abaixo do normal continua; preços outlier_low são exibidos com destaque e disclaimer, mas não viram o "preço relevante" para sugestão.

#### Preço mais frequente, quantidade de notas e recência

Tudo isso sai da mesma tabela `prices` (já temos `receipt_id` e `data_referencia`), sem tabelas novas.

**O que mostrar por (produto, mercado) e por período:**

| Métrica | Como obter |
|--------|-------------|
| **Preço mais frequente no período** | Agrupar por (product_id, store_id, valor_unitario) no período; contar `COUNT(DISTINCT receipt_id)`; o valor com mais notas é a "moda". |
| **Qtd de notas com aquele preço** | Para cada valor distinto no período: `COUNT(DISTINCT receipt_id)`. |
| **Recência** | Para cada valor: `MAX(data_referencia)`. Assim dá para mostrar "R$ 12,90 em 10 notas (última em 05/03)" vs "R$ 13,50 em 10 notas (última em 20/02)". |

**Exemplo (10 notas com X há 5 min, 1 nota com Y com desconto):**

- **Preço relevante (onde comprar / destaque):** R$ X (tem 10 notas; Y tem só 1).
- **Na tela:** R$ X — 10 notas (última em 05/03). R$ Y — 1 nota (05/03) · *Preço bem abaixo do normal — pode ser promoção ou desconto pontual.*

**Sempre mostrar por período?**

Sim. **Sempre exibir preços por período definido**, por exemplo:

- **Últimos 7 dias** — preço relevante (regra ≥2 notas acima), preço mais frequente, qtd de notas, última data.
- **Últimos 30 dias** — idem (resumo: "R$ X em N notas, R$ Y em M notas").

Na UI: abas ou filtros "Última semana" / "Último mês", e em cada um:

- **Preço relevante** (valor com ≥2 notas no período, mais recente; ou último se não houver).
- Preço mais frequente no período (moda) + "em N notas".
- Lista resumida: cada valor distinto + "em N notas" + "última em DD/MM"; valores com 1 nota e muito abaixo do normal com alerta visual + disclaimer.

"Onde é melhor comprar" usa o **preço relevante** (≥2 notas quando existir) por produto/mercado. O alerta de preço muito abaixo do normal continua: preços outlier_low são mostrados com cor/disclaimer e não viram o relevante quando houver outro valor com ≥2 notas.

---

### 8. shopping_lists
Listas de compras do usuário.

| Coluna     | Tipo         | Descrição                |
|------------|--------------|--------------------------|
| id         | BIGSERIAL    | PK                       |
| user_id    | BIGINT       | FK users                 |
| nome       | VARCHAR(100) | ex.: "Compras do mês"   |
| created_at | TIMESTAMPTZ  |                          |
| updated_at | TIMESTAMPTZ  |                          |

---

### 9. shopping_list_items
Itens da lista (produto normalizado ou texto livre).

| Coluna          | Tipo          | Descrição                |
|-----------------|---------------|--------------------------|
| id              | BIGSERIAL     | PK                       |
| list_id         | BIGINT        | FK shopping_lists        |
| product_id      | BIGINT        | FK products_canonical (NULL se ainda não vinculado) |
| descricao_bruta | VARCHAR(255)  | texto livre se product_id NULL |
| quantidade      | NUMERIC(12,3) | 1, 2, 1.5, etc.          |
| created_at      | TIMESTAMPTZ   |                          |

Assim o app consegue mostrar produto por produto e, quando houver `product_id`, buscar preço por mercado e “onde é melhor comprar”.

---

### 10. price_alerts (futuro)
Alertas de preço (ex.: “aviso quando estiver muito abaixo do normal”).

| Coluna      | Tipo          | Descrição                |
|-------------|---------------|--------------------------|
| id          | BIGSERIAL     | PK                       |
| user_id     | BIGINT        | FK users                 |
| product_id  | BIGINT        | FK products_canonical    |
| tipo        | VARCHAR(20)   | 'below_median' / 'max_price' |
| valor_alvo  | NUMERIC(12,2) | opcional                  |
| created_at  | TIMESTAMPTZ   |                          |

---

### 11. price_outliers (lógica de preço fora do normal)
Sinalizar preços suspeitos (possível erro de digitação ou dado ruim).

| Coluna       | Tipo         | Descrição                |
|--------------|--------------|--------------------------|
| id           | BIGSERIAL    | PK                       |
| price_id     | BIGINT       | FK prices                |
| tipo         | VARCHAR(20)  | 'outlier_low' / 'outlier_high' / 'suspicious' |
| motivo       | TEXT         | ex.: ">3 desvios da mediana" |
| created_at   | TIMESTAMPTZ  |                          |

**Lógica sugerida (exemplo):**

- Por `product_id`, calcule mediana (e opcionalmente desvio) dos `valor_unitario` em `prices` (últimos X dias ou todas as observações).
- Se um preço novo estiver, por exemplo, a mais de 2–3 desvios da mediana (muito alto ou muito baixo), criar linha em `price_outliers`.
- No app/API: para “preço em cada mercado”, você pode filtrar `WHERE price_id NOT IN (SELECT price_id FROM price_outliers)` ou dar peso menor para esses preços. Opcional: fila para revisão humana ou descarte.

---

## Resumo do que o app entrega

| Funcionalidade              | Onde no esquema                                      |
|----------------------------|------------------------------------------------------|
| Ver produto e preço        | `products_canonical` + `prices` (por store)          |
| Preço em cada mercado     | `prices` agrupado por `product_id`, `store_id`       |
| Lista de compras           | `shopping_lists` + `shopping_list_items`             |
| Onde é melhor comprar      | Soma de `prices` por lista e por store                |
| Alertas de preço (futuro)  | `price_alerts` + job que compara com `prices`         |
| Preço fora do normal       | `price_outliers` + job que analisa `prices` por produto |

---

## Desconto – resposta direta

- **No XML:** existe campo de desconto por item (`vDesc`) e no total.
- **No HTML que a gente raspa:** em geral **só aparece o preço já com desconto**; não vem “desconto” como campo ou linha separada.
- Para seu uso (comparar preço, lista, alerta), **usar o valor pago (valor_unitario/valor_total)** está correto. Se no futuro o parser ou uma API passar a trazer desconto explícito, basta acrescentar `desconto_item` em `receipt_items_raw` e, se quiser, refletir em `prices`.
