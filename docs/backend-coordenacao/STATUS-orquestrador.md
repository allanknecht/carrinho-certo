# STATUS — Orquestrador

**Atualizar ao menos 1x por sessão.**

**Verificação por agente (checklists + testes, um ficheiro por papel):** [`docs/backend-coordenacao/verificacao-por-agente/README.md`](verificacao-por-agente/README.md) — ler antes de pedir validação cruzada; regras e índice em `TESTES-agente-*.md` (commit de referência da estrutura: `5e91046`).

## Branch base atual para features

- [ ] `main`  [x] `backend`  [ ] outra: `____________`

**Definição:** branch de integração atual do trabalho backend é **`backend`** (tracking `origin/backend`). Features novas devem ramificar a partir de **`backend`** atualizado, salvo decisão contrária do time.

*(Se o time passar a integrar só em `main`, marcar `main` e desmarcar `backend` aqui e no histórico.)*

## Ordem de merge sugerida

1. **Fase 1 (paralelo, ordem de merge flexível):** PRs de **RF09 Listas**, **Catálogo** e **LGPD** — podem entrar em qualquer ordem enquanto não houver conflito; **prioridade lógica:** mergear **RF09 antes** quando possível, para desbloquear RF10 e fixar contrato de listas no plano.
2. **RF10 (preços por lista):** após **RF09** estar na branch base **ou** com contrato de `shopping_list_items` fixo em `plano-backend-paralelo.md` (secção Contrato).
3. **RF08 Outliers:** após **RF10** ou em branch isolada com acordo explícito em `ProductPricesSummary` / `pricing/` (evitar dois agentes no mesmo ficheiro no mesmo sprint).

## Bloqueios entre agentes

- **Verificação:** pasta `verificacao-por-agente/` consolidada (README com `/rails`, `db:test:prepare`, textos para a equipa; um `TESTES-agente-*.md` por papel). Quem concluir testes deve opcionalmente preencher a tabela no **seu** `TESTES-*`.
- **CI local:** quem não tem Postgres no host usa Docker (`COMUNICACAO.md`); relatórios do tipo “não corri testes aqui” são esperados — a validação forte é no container com `api_test`.
- **Atenção:** vários PRs a tocarem `config/routes.rb` no mesmo período podem exigir commit agregado de rotas (orquestrador ou agente designado).

## Contratos / decisões registradas (ponteiro para `plano-backend-paralelo.md` seção Contrato)

- **`plano-backend-paralelo.md` — Contrato mínimo:** Catálogo fechado (ponteiro para `api-contrato.md` §3); RF09 consolidado com rotas/payloads; RF10 ainda a fechar; nota RF08 sobre `price_outlier_assessment.rb`.
- Detalhe de payloads: ver também `COMUNICACAO.md` (digest) e `docs/api-contrato.md`.

## Comunicação entre agentes

- **Digest e protocolo:** `COMUNICACAO.md` — atualizado pelo orquestrador ao reler os STATUS; agentes não sobrescrevem o STATUS alheio.
- **Verificação backend (1 ficheiro por papel, evita conflitos Git):** [`verificacao-por-agente/README.md`](verificacao-por-agente/README.md) — regras, Docker, índice `TESTES-agente-*.md` (Catálogo, RF09 listas, LGPD, RF10 `store_rankings`, RF08 `price_outlier` + preços do produto). Contrato: `docs/api-contrato.md`.

## Histórico breve

| Data       | Ação |
|------------|------|
| 2026-04-11 | Branch base definida: `backend`. Ordem de merge e bloqueios inicializados. Contrato permanece rascunho até handoff dos agentes. |
| 2026-04-11 | Adicionado `COMUNICACAO.md` (canais + digest). Relido: todos os `STATUS-agente-*` ainda por preencher; sem alterações novas em `api-contrato.md` para features paralelas. |
| 2026-04-11 | Digest atualizado: código local sugere RF09/Catálogo/RF08 em curso; STATUS ainda vazio; §4 `api-contrato` desalinhada com rotas de listas. Plano — secção Contrato atualizada (Catálogo + RF09 + nota RF08). |
| 2026-04-11 | Pasta `docs/backend-coordenacao/verificacao-por-agente/` com `TESTES-agente-*.md` (checklist por papel). Commit de referência: `5e91046`. |
| 2026-04-11 | `verificacao-por-agente/README.md`: regras, Docker, índice por papel, mensagens curtas/longas para a equipa; comandos com `db:test:prepare && bin/rails test` no `WORKDIR` `/rails` do container; outliers unifica serviço + `product_prices_controller_test`. |
| 2026-04-11 | `COMUNICACAO.md`: canal + regra para não editar `TESTES-agente-*.md` alheios; `README.md` da coordenação com tabela papel → ficheiro. |
| 2026-04-11 | Equipa alinhou `verificacao-por-agente/` (Docker `WORKDIR` `/rails`, copy-paste para equipa). Bloqueios antigos (§4 skeleton vs listas) removidos — `api-contrato.md` já tem §5 Shopping lists. |
