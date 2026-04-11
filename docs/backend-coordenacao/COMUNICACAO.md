# Comunicação entre agentes (backend)

Ficheiro **partilhado** onde o **orquestrador** resume o que cada papel está a fazer e como nos coordenamos. Os agentes de implementação **não editam** este ficheiro para “falar” uns com os outros — usam o **próprio** `STATUS-agente-*.md`; o orquestrador consolida aqui.

---

## Canais (o que usar para quê)

| Canal | Quem escreve | Conteúdo |
|--------|----------------|----------|
| `STATUS-agente-<papel>.md` | **Só** o agente desse papel | Estado, branch, ficheiros, bloqueios, handoff (ex.: RF09 → RF10). |
| `STATUS-orquestrador.md` | Orquestrador | Branch base, ordem de merge, bloqueios globais, ponteiro para contratos. |
| **`COMUNICACAO.md` (este)** | Orquestrador | Protocolo + **digest** do que cada um está a fazer (leitura dos STATUS + plano). |
| `plano-backend-paralelo.md` | Orquestrador (secção Contrato após alinhamento) | Dependências, divisão de ficheiros, **contrato mínimo** consolidado. |
| `docs/api-contrato.md` | Cada agente na **sua** secção / orquestrador se unificar | Endpoints e payloads expostos ao cliente. |

**Regra:** não editar o `STATUS` de outro agente. Dúvidas cruzadas (ex.: RF10 vs Outliers no mesmo ficheiro) → marcar bloqueio no **próprio** STATUS e avisar no digest (orquestrador regista em `STATUS-orquestrador.md`).

---

## Digest — o que cada um está a fazer

*Atualizado pelo orquestrador ao reler os `STATUS-agente-*.md` e o plano.*

| Papel | Estado (pelo último STATUS) | Notas / próximo passo esperado |
|--------|-------------------------------|----------------------------------|
| **RF09 Listas** | Não iniciado (template por preencher) | Migrations, modelos, CRUD listas/itens; preencher Handoff para RF10 quando houver modelo. |
| **Catálogo** | Não iniciado | `GET /products` (q, paginação); documentar params em STATUS + `api-contrato.md`. |
| **LGPD** | Não iniciado | DELETE conta + anonimização `receipts`; documentar rota e comportamento no STATUS. |
| **RF10 Preços** | Não iniciado | Aguardar RF09 mergeado **ou** contrato de itens fixo no plano; base de rebase explícita. |
| **RF08 Outliers** | Não iniciado | Coordenar com RF10/orquestrador se tocar `ProductPricesSummary` em paralelo. |

**Resumo:** ainda **nenhum** agente marcou “Em progresso” ou preencheu branch/data nos STATUS — sprint em arranque ou ficheiros ainda não commitados localmente.

---

## Histórico de digest (trechos)

| Data | Observação |
|------|------------|
| 2026-04-11 | Criação do digest; todos os STATUS-agente ainda vazios. `docs/api-contrato.md` sem secções novas para listas/catálogo/LGPD/RF10 nesta leitura. |

---

## Quem pede o quê a quem (referência rápida)

- **RF10** precisa de **RF09** (ou contrato fixo no plano): ver `STATUS-agente-listas.md` e secção Contrato em `plano-backend-paralelo.md`.
- **RF08** evita colisão com **RF10** em `app/services/pricing/` / `product_prices_summary` — combinar no STATUS + orquestrador.
- **Rotas** (`config/routes.rb`): vários PRs → possível commit agregado; orquestrador ou agente designado unifica.
