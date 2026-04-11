# Verificação — Agente LGPD (RF11)

**Escopo:** `DELETE /account` (utilizador autenticado), efeitos em `users`, listas, e anonimização de `receipts` (`user_id` NULL).  
**Não é da tua responsabilidade:** catálogo, ranking por lista, outliers isoladamente (exceto garantir que notas não são apagadas indevidamente).

---

## Pré-requisitos

- Docker + API; testes dentro do container.
- Para smoke manual: utilizador **dedicado** a apagar (não uses a conta principal de desenvolvimento se precisares dela depois).

---

## 1. Testes automatizados (obrigatório)

```bash
bin/rails test test/controllers/accounts_controller_test.rb
```

Esperado: **0 falhas**.

---

## 2. Smoke manual (opcional, cuidado)

1. Criar user, login, `TOKEN`.

2. Opcional: criar `POST /receipts` com URL válida **ou** inserir receita de teste pela BD/seeds, de modo a existir `receipts.user_id` = teu user.

3. Chamar:

```bash
curl -s -o /dev/null -w "%{http_code}" -X DELETE http://localhost:3000/account \
  -H "Authorization: Bearer TOKEN"
```

Esperado: **204**.

4. Tentar login de novo com o mesmo email — deve falhar (utilizador removido).

5. Se tiveres acesso à BD: confirmar que `receipts` desse utilizador ficaram com `user_id` NULL e que `chave_acesso` não foi apagada (conforme contrato).

---

## 3. Contrato

`docs/api-contrato.md` — secção de conta / exclusão (e notas relacionadas).

---

## Resultado da verificação *(opcional; só editar este ficheiro)*

| Data | Testes auto | Smoke manual | Notas |
|------|-------------|--------------|-------|
|      | OK / falha  | OK / N/A     |       |
