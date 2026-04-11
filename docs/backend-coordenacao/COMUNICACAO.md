# Comunicação entre agentes (backend)

Ficheiro **partilhado** onde o **orquestrador** resume o que cada papel está a fazer e como nos coordenamos. Os agentes de implementação **não editam** este ficheiro para “falar” uns com os outros — usam o **próprio** `STATUS-agente-*.md`; o orquestrador consolida aqui.

---

## Canais (o que usar para quê)

| Canal | Quem escreve | Conteúdo |
|--------|----------------|----------|
| `STATUS-agente-<papel>.md` | **Só** o agente desse papel | Estado, branch, ficheiros, bloqueios, handoff (ex.: RF09 → RF10). |
| `STATUS-orquestrador.md` | Orquestrador | Branch base, ordem de merge, bloqueios globais, ponteiro para contratos. |
| **`COMUNICACAO.md` (este)** | Orquestrador | Protocolo + **digest** do que cada um está a fazer (leitura dos STATUS + plano +, quando necessário, `api-contrato` / árvore `backend/api`). |
| `plano-backend-paralelo.md` | Orquestrador (secção *Contrato* após alinhamento) | Dependências, divisão de ficheiros, **contrato mínimo** consolidado. |
| `docs/api-contrato.md` | Cada agente na **sua** secção / orquestrador se unificar | Endpoints e payloads expostos ao cliente. |

**Regra:** não editar o `STATUS` de outro agente. Dúvidas cruzadas (ex.: RF10 vs Outliers no mesmo ficheiro) → marcar bloqueio no **próprio** STATUS e o orquestrador regista em `STATUS-orquestrador.md`.

**Atualização do digest:** o orquestrador relê os `STATUS-agente-*.md` sempre que possível e cruza com o plano e com o contrato HTTP; se os STATUS estiverem vazios mas existir trabalho na árvore, o digest indica essa **dessincronia** para os agentes atualizarem o seu ficheiro.

---

## Digest — o que cada um está a fazer

*Última passagem pelo orquestrador: 2026-04-11 (inclui leitura de `api-contrato.md`, `config/routes.rb` e controladores/modelos em `backend/api` não necessariamente commitados).*

| Papel | Estado (pelo último STATUS) | O que o repositório sugere (para alinhar STATUS) |
|--------|-------------------------------|--------------------------------------------------|
| **RF09 Listas** | Template por preencher | Rotas aninhadas `shopping_lists` + `items`; modelos `ShoppingList` / `ShoppingListItem`; payloads JSON no concern `ShoppingListItemJson`. **Pendência:** `docs/api-contrato.md` §4 ainda fala em “skeleton / not implemented” — atualizar secção §4 quando o contrato HTTP estiver fechado. |
| **Catálogo** | Template por preencher | Contrato **§3** em `api-contrato.md` completo (`GET /products`, `q`, `page`, `per`, `meta`). Rotas: `resources :products, only: [:index]`. |
| **LGPD** | Template por preencher | `User` com `has_many :shopping_lists, dependent: :destroy`; sem alteração de rotas visível nesta leitura para exclusão de conta — confirmar RF11 no STATUS quando existir rota/serviço. |
| **RF10 Preços** | Template por preencher | Ainda sem rota de “sugestão por lista” na leitura atual; depende de RF09 estável — ver secção Contrato no plano. |
| **RF08 Outliers** | Template por preencher | Ficheiro `app/services/pricing/price_outlier_assessment.rb` presente (lógica isolada; coordenar com quem toca `ProductPricesSummary`). |

**Resumo:** os **STATUS-agente-* continuam por preencher**; há **sinal forte** de trabalho em RF09, Catálogo e RF08 no código. Pedido aos agentes: **preencher o próprio STATUS** (branch, data, checklist) para o digest depender só dos STATUS, não da inspeção da árvore.

---

## Histórico de digest (trechos)

| Data | Observação |
|------|------------|
| 2026-04-11 | Criação do digest; todos os STATUS-agente vazios. |
| 2026-04-11 | Digest enriquecido: `api-contrato` §3 alinhado com catálogo; §4 desatualizada vs rotas de listas; código RF09/RF08 visível na árvore — STATUS ainda não espelha. Plano atualizado (secção Contrato): Catálogo fechado; RF09 consolidado. |

---

## Quem pede o quê a quem (referência rápida)

- **RF10** precisa de **RF09** (ou contrato fixo no plano): ver `STATUS-agente-listas.md` e secção Contrato em `plano-backend-paralelo.md`.
- **RF08** evita colisão com **RF10** em `ProductPricesSummary` — `PriceOutlierAssessment` como sítio para regra sem colidir; combinar no STATUS + orquestrador.
- **Rotas** (`config/routes.rb`): vários PRs → possível commit agregado; orquestrador ou agente designado unifica.
