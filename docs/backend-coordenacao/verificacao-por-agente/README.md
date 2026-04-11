# Verificação manual por agente (sem conflito de edição)

Cada papel tem **um ficheiro próprio** `TESTES-agente-*.md`. Assim, várias pessoas podem registar resultados ou notas **em paralelo** sem mexer no mesmo ficheiro.

## Regras

1. **Só edita o ficheiro com o teu papel** (ex.: quem fez Catálogo → `TESTES-agente-catalogo.md`). Não alteres os `TESTES-*` dos outros.
2. Opcional: no **fim** do teu ficheiro, usa a secção **Resultado da verificação** (data, OK/falha, notas).
3. Ambiente: seguir **Docker** em `../COMUNICACAO.md` antes de `bin/rails` ou `curl` contra a API.

## Índice

| Ficheiro | Papel |
|----------|--------|
| [TESTES-agente-catalogo.md](TESTES-agente-catalogo.md) | Busca/listagem `GET /products` |
| [TESTES-agente-listas-rf09.md](TESTES-agente-listas-rf09.md) | Listas e itens (RF09) |
| [TESTES-agente-lgpd.md](TESTES-agente-lgpd.md) | Exclusão de conta (RF11) |
| [TESTES-agente-rf10-precos.md](TESTES-agente-rf10-precos.md) | Ranking de lojas por lista (RF10) |
| [TESTES-agente-outliers-rf08.md](TESTES-agente-outliers-rf08.md) | Preço atípico em `GET /products/:id/prices` (RF08) |

Contrato HTTP de referência: `docs/api-contrato.md` (na raiz do repo, fora desta pasta).
