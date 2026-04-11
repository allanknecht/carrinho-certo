# STATUS — Orquestrador

**Atualizar ao menos 1x por sessão.**

## Branch base atual para features

- [ ] `main`  [x] `backend`  [ ] outra: `____________`

**Definição:** branch de integração atual do trabalho backend é **`backend`** (tracking `origin/backend`). Features novas devem ramificar a partir de **`backend`** atualizado, salvo decisão contrária do time.

*(Se o time passar a integrar só em `main`, marcar `main` e desmarcar `backend` aqui e no histórico.)*

## Ordem de merge sugerida

1. **Fase 1 (paralelo, ordem de merge flexível):** PRs de **RF09 Listas**, **Catálogo** e **LGPD** — podem entrar em qualquer ordem enquanto não houver conflito; **prioridade lógica:** mergear **RF09 antes** quando possível, para desbloquear RF10 e fixar contrato de listas no plano.
2. **RF10 (preços por lista):** após **RF09** estar na branch base **ou** com contrato de `shopping_list_items` fixo em `plano-backend-paralelo.md` (secção Contrato).
3. **RF08 Outliers:** após **RF10** ou em branch isolada com acordo explícito em `ProductPricesSummary` / `pricing/` (evitar dois agentes no mesmo ficheiro no mesmo sprint).

## Bloqueios entre agentes

- **Coordenação / documentação:** os ficheiros `STATUS-agente-*.md` **ainda não refletem** o trabalho visível em `backend/api` (listas, catálogo, outliers). Pedido: cada agente preencher o seu STATUS ao iniciar/concluir para o digest não depender só da inspeção da árvore.
- **Contrato HTTP:** `docs/api-contrato.md` **§4** ainda indica listas como “skeleton / not implemented” enquanto `routes.rb` expõe CRUD de `shopping_lists` e itens — **Agente Listas** (ou PR único) deve alinhar §4 com os payloads reais.
- **Atenção:** unificação de `config/routes.rb` pode precisar de um commit agregado (orquestrador ou um agente designado) se vários PRs tocarem rotas no mesmo período.

## Contratos / decisões registradas (ponteiro para `plano-backend-paralelo.md` seção Contrato)

- **`plano-backend-paralelo.md` — Contrato mínimo:** Catálogo fechado (ponteiro para `api-contrato.md` §3); RF09 consolidado com rotas/payloads; RF10 ainda a fechar; nota RF08 sobre `price_outlier_assessment.rb`.
- Detalhe de payloads: ver também `COMUNICACAO.md` (digest) e `docs/api-contrato.md`.

## Comunicação entre agentes

- **Digest e protocolo:** `COMUNICACAO.md` — atualizado pelo orquestrador ao reler os STATUS; agentes não sobrescrevem o STATUS alheio.
- **Verificação manual (1 ficheiro por papel, evita conflitos Git):** `verificacao-por-agente/README.md`.

## Histórico breve

| Data       | Ação |
|------------|------|
| 2026-04-11 | Branch base definida: `backend`. Ordem de merge e bloqueios inicializados. Contrato permanece rascunho até handoff dos agentes. |
| 2026-04-11 | Adicionado `COMUNICACAO.md` (canais + digest). Relido: todos os `STATUS-agente-*` ainda por preencher; sem alterações novas em `api-contrato.md` para features paralelas. |
| 2026-04-11 | Digest atualizado: código local sugere RF09/Catálogo/RF08 em curso; STATUS ainda vazio; §4 `api-contrato` desalinhada com rotas de listas. Plano — secção Contrato atualizada (Catálogo + RF09 + nota RF08). |
| 2026-04-11 | Pasta `verificacao-por-agente/` com `TESTES-agente-*.md` (checklist por papel). |
