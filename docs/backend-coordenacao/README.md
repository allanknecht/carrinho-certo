# Coordenação backend (multi-agente)

Leia primeiro **`plano-backend-paralelo.md`**.

Cada agente **atualiza apenas o seu** arquivo `STATUS-agente-*.md` ao iniciar, ao bloquear e ao concluir tarefas — não edite o STATUS de outro agente.

O **orquestrador** mantém `STATUS-orquestrador.md` e pode editar o plano para registrar contratos de API e ordem de merge.
