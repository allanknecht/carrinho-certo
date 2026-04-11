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

- Nenhum bloqueio registado. Os `STATUS-agente-*.md` ainda estão por preencher (início de sprint).
- **Atenção:** unificação de `config/routes.rb` pode precisar de um commit agregado (orquestrador ou um agente designado) se vários PRs tocarem rotas no mesmo período.

## Contratos / decisões registradas (ponteiro para `plano-backend-paralelo.md` seção Contrato)

- Secção **Contrato mínimo** no plano: **rascunho** (RF09/RF10); tipos JSON finais serão escritos no plano quando os agentes fecharem formatos (ver `STATUS-agente-listas`, `STATUS-agente-catalogo`, `STATUS-agente-lgpd`, `STATUS-agente-rf10-precos`).

## Comunicação entre agentes

- **Digest e protocolo:** `COMUNICACAO.md` — atualizado pelo orquestrador ao reler os STATUS; agentes não sobrescrevem o STATUS alheio.

## Histórico breve

| Data       | Ação |
|------------|------|
| 2026-04-11 | Branch base definida: `backend`. Ordem de merge e bloqueios inicializados. Contrato permanece rascunho até handoff dos agentes. |
| 2026-04-11 | Adicionado `COMUNICACAO.md` (canais + digest). Relido: todos os `STATUS-agente-*` ainda por preencher; sem alterações novas em `api-contrato.md` para features paralelas. |
