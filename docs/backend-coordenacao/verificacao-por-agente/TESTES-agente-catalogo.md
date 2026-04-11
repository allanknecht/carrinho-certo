# Verificação — Agente Catálogo

**Escopo:** `GET /products` (descoberta de `products_canonical`, paginação, `q`).  
**Não é da tua responsabilidade:** listas, `/account`, preços por produto, ranking por lista.

---

## Pré-requisitos

- Stack Docker em pé (`docker compose up -d` na raiz do repo). Comandos Rails **dentro** do serviço `api` — ver `COMUNICACAO.md` (pasta pai).
- Base preparada: `bin/rails db:prepare` (development) se necessário.

---

## 1. Testes automatizados (obrigatório)

Dentro do container, em `backend/api`:

```bash
bin/rails test test/controllers/products_controller_test.rb
```

Esperado: **0 falhas**.

---

## 2. Smoke manual (opcional, com token)

1. Criar utilizador e obter token (ajusta URL se o compose expuser outra porta):

```bash
curl -s -X POST http://localhost:3000/users -H "Content-Type: application/json" \
  -d "{\"email\":\"catalogo-test@example.com\",\"password\":\"password123\"}"

curl -s -X POST http://localhost:3000/auth/login -H "Content-Type: application/json" \
  -d "{\"email\":\"catalogo-test@example.com\",\"password\":\"password123\"}"
```

2. Com o `token` devolvido:

```bash
curl -s "http://localhost:3000/products?page=1&per=5" \
  -H "Authorization: Bearer SEU_TOKEN"
```

3. Confirmar: resposta `200`, corpo com `products` (array) e `meta` (`page`, `per`, `total`, `total_pages`).

4. Repetir com `q=` parcial (ex.: primeira sílaba de um `display_name` existente na BD) e verificar filtro.

---

## 3. Contrato

Conferir com `docs/api-contrato.md` — secção do catálogo de produtos (search / list).

---

## Resultado da verificação *(opcional; só editar este ficheiro)*

| Data | Testes auto | Smoke manual | Notas |
|------|-------------|--------------|-------|
|      | OK / falha  | OK / N/A     |       |
