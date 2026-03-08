# Carrinho Certo

App em que usuários escaneiam o QR da NFC-e, o sistema normaliza os produtos e preços e sugere onde fazer as compras. Inclui listas de compras, preço por mercado (com histórico e preço relevante) e alertas de preço.

---

## Estrutura do repositório

- **backend/** — API Ruby + Worker Ruby (mesmo repo): recebe notas, processa, normaliza, persiste no PostgreSQL.
- **app-mobile/** — App .NET MAUI: telas, scan QR, listas, “onde comprar”.
- **docs/** — Documentação (esquema do banco, estrutura do repo).

Ver [docs/estrutura-repositorio.md](docs/estrutura-repositorio.md) para detalhes.

---

## Documentação

| Documento | Conteúdo |
|-----------|----------|
| [docs/estrutura-repositorio.md](docs/estrutura-repositorio.md) | Estrutura do repo, API + Worker no mesmo repositório. |
| [docs/schema-banco.md](docs/schema-banco.md) | Esquema do banco, tabelas, regras de preço relevante (≥2 notas), histórico, outliers. |

---

## Stack

- **Backend:** Ruby (API + Worker), PostgreSQL.
- **App:** .NET MAUI.
