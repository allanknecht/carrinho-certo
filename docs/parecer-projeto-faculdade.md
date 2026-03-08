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
| **Modelo de dados** | Esquema completo (11 tabelas), tipos, chaves e regras de negócio (preço relevante ≥2 notas, outliers, LGPD) em [schema-banco.md](schema-banco.md). |
| **Arquitetura** | Estrutura do repositório (monorepo), backend API + Worker, app MAUI, em [estrutura-repositorio.md](estrutura-repositorio.md). |
| **Telas do aplicativo** | Lista de telas do app mobile (autenticação, envio de nota, produtos, listas de compras, conta), alinhadas aos requisitos, em [telas-do-app.md](telas-do-app.md). |
| **Regras de negócio** | Preço relevante, histórico por período, detecção de outlier e política de exclusão de dados (LGPD) descritas no schema. |
| **Stack tecnológica** | Definida (Ruby, PostgreSQL, .NET MAUI). |
| **Conformidade LGPD** | Política de exclusão de conta descrita: anonimização de `user_id` em `receipts`, preservação de notas e histórico de preços. |

---

## Itens pendentes de documentação

Documentos ou seções ainda não elaborados e recomendados para fechamento da base documental:

| # | Item | Recomendação |
|---|------|--------------|
| 1 | **Autenticação** | Documentar o fluxo de autenticação (e-mail + senha, JWT, OAuth), armazenamento de credenciais (hash) e uso de token na API. |
| 2 | **Contrato da API** | Elaborar especificação dos endpoints (método, path, corpo e resposta) ou documento OpenAPI/Swagger. |
| 3 | **Diagrama de arquitetura** | Incluir diagrama (ex.: Mermaid) representando App → API → Banco; Worker → Banco; fila de jobs. |
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
