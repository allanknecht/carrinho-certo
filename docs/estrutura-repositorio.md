# Estrutura do repositório – Carrinho Certo

Repositório único (monorepo) com todo o projeto: backend em Ruby (API + Worker), app mobile em .NET MAUI e documentação.

---

## Visão geral

```
carrinho-certo/
├── backend/           # API Ruby + Worker Ruby (mesmo repo)
│   ├── api/          # API (Rails ou Sinatra) — recebe notas, usuários, listas
│   ├── worker/       # Worker (Sidekiq ou job) — processa notas, normaliza, salva
│   └── lib/          # Código compartilhado (ingestão NFC-e, normalização, lógica de negócio)
├── app-mobile/       # App .NET MAUI — telas, scan QR, listas, “onde comprar”
├── docs/             # Documentação (esquema do banco, decisões, etc.)
└── README.md
```

---

## Backend: API + Worker no mesmo repo

O backend fica todo em **Ruby**, em um único repositório:

- **API** — expõe endpoints para o app: envio de nota (URL/QR), listas, preços por produto/mercado, “onde é melhor comprar”, etc. Persiste no PostgreSQL.
- **Worker** — processa jobs assíncronos: ingestão da nota (consulta NFC-e), normalização (regras + LLM), gravação em `receipts`, `receipt_items_raw`, `prices`, detecção de outliers, etc.

API e Worker compartilham o mesmo código (por exemplo em `lib/`), o mesmo banco e a mesma configuração de ambiente. São dois processos diferentes (servidor HTTP e processo de fila), mas vivem no **mesmo repo** e na mesma base de código.

---

## App mobile

Front-end em **.NET MAUI**: telas, design, scan de QR, chamadas à API, listas de compras, sugestão de “onde comprar”. Não fica no backend; consome apenas a API.

---

## Documentação

Em `docs/`:

- **schema-banco.md** — esquema do banco (tabelas, regras de preço relevante, histórico, outliers).
- **estrutura-repositorio.md** — este arquivo (estrutura do repo, API + Worker no mesmo repo).
