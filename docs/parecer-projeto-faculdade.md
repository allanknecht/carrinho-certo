# Status da documentação – Carrinho Certo

Este documento consolida o **estado atual da documentação** do projeto Carrinho Certo, indicando o que já está coberto e o que permanece **pendente** para completar a base documental.

---

## Documentação já disponível

| Item | Situação |
|------|----------|
| **Escopo e problema** | Definição clara do problema (comparação de preços entre mercados a partir de NFC-e), listas de compras e sugestão de onde comprar. |
| **Objetivos e justificativa** | Documentados em [objetivos-requisitos-casos-de-uso.md](objetivos-requisitos-casos-de-uso.md): problema, objetivo geral, objetivos específicos, justificativa e público-alvo. |
| **Requisitos** | Requisitos funcionais e não funcionais numerados (RF01–RF11, RNF01–RNF04) no mesmo documento. |
| **Diagrama ER** | Modelo entidade-relacionamento em Mermaid, alinhado ao [schema do banco](schema-banco.md), no documento de objetivos e casos de uso. |
| **Casos de uso e fluxos** | Atores, casos de uso (UC01–UC07) e fluxos principais (envio de nota, exclusão de conta) documentados. |
| **Modelo de dados** | [schema-banco.md](schema-banco.md) em inglês: tabelas **implementadas** (users, stores, receipts, receipt_items_raw), pipeline de processamento, tabelas planejadas e LGPD. |
| **Arquitetura** | [estrutura-repositorio.md](estrutura-repositorio.md) (inglês): monorepo, Rails API + Active Job. |
| **Telas do aplicativo** | Lista de telas do app mobile (autenticação, envio de nota, produtos, listas de compras, conta), alinhadas aos requisitos, em [telas-do-app.md](telas-do-app.md). |
| **Regras de negócio** | Preço relevante, histórico por período, detecção de outlier e política de exclusão de dados (LGPD) descritas no schema. |
| **Stack tecnológica** | Definida (Ruby, PostgreSQL, .NET MAUI). |
| **Conformidade LGPD** | Política de exclusão de conta descrita: anonimização de `user_id` em `receipts`, preservação de notas e histórico de preços. |

---

## Itens pendentes de documentação

Documentos ou seções ainda não elaborados e recomendados para fechamento da base documental:

| # | Item | Recomendação |
|---|------|--------------|
| 1 | **Autenticação** | Parcialmente coberto em [api-contrato.md](api-contrato.md) (inglês): e-mail + senha, `password_digest`, Bearer token. Completar com diagrama de fluxo e, se desejado, OpenAPI. |
| 2 | **Contrato da API** | Parcialmente coberto em [api-contrato.md](api-contrato.md) (inglês). Pendente: OpenAPI/Swagger. Leitura de notas por usuário não faz parte do contrato (contribuição para base agregada). |
| 3 | **Diagrama de arquitetura** | Incluir diagrama (ex.: Mermaid): App → API → PostgreSQL; Active Job → parser HTTP → PostgreSQL. |
| 4 | **Normalização do modelo de dados** | Incluir em `schema-banco.md` subseção que explicite a aderência às formas normais (1FN, 2FN, 3FN), com exemplos. |
| 5 | **Estratégia de testes** | Documentar abordagem de testes (unitários, integração, e2e) e ferramentas previstas (RSpec, xUnit, etc.). |
| 6 | **Cronograma** | Definir e documentar fases e marcos (ex.: Fase 1 – API e banco; Fase 2 – Worker; Fase 3 – App MVP). |
| 7 | **Referências** | Incluir seção de referências (legislação LGPD, documentação NFC-e/SEFAZ, normas técnicas utilizadas). |

---

## Resumo

| Aspecto | Status |
|--------|--------|
| **Cobertura atual** | Objetivos, justificativa, requisitos (RF/RNF), diagrama ER e casos de uso estão em [objetivos-requisitos-casos-de-uso.md](objetivos-requisitos-casos-de-uso.md); modelo de dados e arquitetura nos demais documentos listados. A documentação atual cobre escopo, requisitos, modelo de dados e fluxos principais. |
| **Pendências** | Itens listados na seção **Itens pendentes de documentação** (autenticação, contrato da API, diagrama de arquitetura, normalização em texto, estratégia de testes, cronograma, referências). |

Recomenda-se tratar os itens pendentes conforme a prioridade do projeto e a necessidade de alinhamento com equipe e stakeholders.

---

## Implementation status (English)

**Backend (Rails API)** — as of recent sprint:

- **Auth:** `POST /users`, `POST /auth/login`, `Authorization: Bearer <token>` on protected routes.
- **Receipts:** `POST /receipts` accepts flat JSON `{ "source_url": "..." }`, returns `202` with `queued`; `409` if access key from URL already exists.
- **Job:** `ProcessReceiptJob` fetches URL, runs `NfceConsultationParser` (NF-e XML + HTML, including SVRS QrCode layout), persists `stores`, `receipts`, `receipt_items_raw`; statuses `queued` → `processing` → `done` / `failed`.
- **DB:** `users`, `stores`, `receipts`, `receipt_items_raw`, `products_canonical`, `product_aliases` (see [schema-banco.md](schema-banco.md)).
- **Normalization:** `ProductNormalization::TextNormalizer` + `AssignCanonical` after each parsed line; optional **local LLM** via OpenAI-compatible API (Ollama, env `PRODUCT_NORMALIZATION_LLM_ENABLED`); aliases merge variants (`source`: manual / `llm` / heuristic `new_canonical`).

**Not implemented yet:** `prices` table and product price API, shopping list endpoints. **Receipt listing/detail** is intentionally omitted from the API (collective data contribution model).
