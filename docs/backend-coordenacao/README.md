# Coordenação backend (multi-agente)

Leia primeiro **`plano-backend-paralelo.md`**.

**Antes de correr Rails (migrate, test, etc.):** ver secção **Ambiente: Docker** em **`COMUNICACAO.md`** — é obrigatório `docker compose up` e executar comandos **dentro** do container `api`.

Cada agente **atualiza apenas o seu** arquivo `STATUS-agente-*.md` ao iniciar, ao bloquear e ao concluir tarefas — não edite o STATUS de outro agente.

O **orquestrador** mantém `STATUS-orquestrador.md`, o digest e o protocolo partilhado em **`COMUNICACAO.md`** (inclui Docker) e pode editar o plano para registrar contratos de API e ordem de merge.

**Verificação manual por papel (um ficheiro por agente, sem conflito):** pasta **`verificacao-por-agente/`** — começar pelo `README.md` dentro dela.
