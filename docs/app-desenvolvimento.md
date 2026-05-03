# Desenvolvimento do app (.NET MAUI) com a API local

Este guia é para quem vai **integrar o aplicativo** (`frontend/CarrinhoCerto`) com o **backend Rails** em desenvolvimento. Lista de endpoints e payloads em português: **[frontend-guia-api-e-ordem.md](frontend-guia-api-e-ordem.md)**. Contrato canónico (inglês): **[api-contrato.md](api-contrato.md)**. Aqui fica o **como fazer** no dia a dia (Docker, rede, testes rápidos).

---

## 1. O que você precisa instalado

| Ferramenta | Para quê |
|------------|----------|
| **Git** | Clonar o repositório |
| **Docker Desktop (Windows)** | Subir PostgreSQL + API sem instalar Ruby/Postgres no PC |
| **.NET SDK** (versão compatível com o `CarrinhoCerto.csproj`) | Build e run do MAUI |
| **Visual Studio 2022** ou **VS Code** + workload MAUI | Desenvolver o app |

### Instalar Docker Desktop (Windows)

1. Baixe em [https://www.docker.com/products/docker-desktop/](https://www.docker.com/products/docker-desktop/).
2. Instale e **reinicie** se pedido.
3. Abra o Docker Desktop e espere ficar “Running”.
4. Opcional: em *Settings → General*, marque “Use the WSL 2 based engine” (recomendado no Windows 10/11).

Sem Docker, você precisaria instalar Ruby, Bundler, PostgreSQL e rodar `rails` manualmente — o time padronizou **Docker** para o backend.

---

## 2. Subir o backend (API + banco)

Na **raiz do repositório** (pasta `carrinho-certo`, onde está o `docker-compose.yml`):

```powershell
docker compose up -d
```

Isso sobe:

- **`db`** — PostgreSQL na porta **5432** (host).
- **`api`** — Rails na porta **3000** (host).

Verifique:

```powershell
docker compose ps
```

Os serviços `db` e `api` devem estar `Up` (e `db` saudável).

### Primeira vez: migrações e seeds (opcional, dados de demo)

Com a API no ar:

```powershell
docker compose exec -T api bash -lc "cd /rails && bin/rails db:migrate"
docker compose exec -T api bash -lc "cd /rails && RAILS_ENV=development bin/rails db:seed"
```

O seed de demo de preços (quando habilitado) cria produtos de teste úteis para telas de busca/preço.

### Testar se a API responde

No navegador: **http://localhost:3000/up** — deve retornar página de health (status 200).

No PowerShell (teste rápido):

```powershell
curl.exe -s -o NUL -w "%{http_code}" http://localhost:3000/up
```

Deve imprimir `200`.

---

## 3. Onde está o projeto do app

- Caminho: **`frontend/CarrinhoCerto/`**
- Solução/projeto: **`CarrinhoCerto.csproj`**

O repositório **não** usa mais a pasta `app-mobile/` — o cliente MAUI é este projeto em `frontend/`.

---

## 4. Conectar o app MAUI à API (URL base)

O backend em desenvolvimento expõe **HTTP** (não HTTPS) em **`http://HOST:3000`**. O `HOST` depende de **onde o app está rodando**.

| Onde o app roda | URL típica da API |
|-----------------|-------------------|
| **Windows** (WinUI / mesmo PC que o Docker) | `http://localhost:3000` ou `http://127.0.0.1:3000` |
| **Emulador Android** | `http://10.0.2.2:3000` — o `10.0.2.2` é o alias do **host** da máquina vista de dentro do emulador |
| **Simulador iOS** (Mac) | `http://localhost:3000` (se o simulador e o Docker rodarem no mesmo Mac) |
| **Celular físico** (mesma rede Wi‑Fi do PC) | `http://IP_DO_SEU_PC:3000` — descubra o IP com `ipconfig` (IPv4 da interface Wi‑Fi/Ethernet) |

### Firewall (dispositivo físico)

No Windows, pode ser necessário permitir entrada na porta **3000** para a rede privada, ou o celular não alcança o PC.

### HTTP sem HTTPS (Android)

Por padrão, Android bloqueia tráfego HTTP claro. Para desenvolvimento, o projeto MAUI/Android costuma precisar de **`android:usesCleartextTraffic="true"`** no `AndroidManifest.xml` ou de uma *network security config* que libere o IP do seu backend. Sem isso, as chamadas falham silenciosamente ou com erro de cleartext.

---

## 5. Implementação sugerida no app (HttpClient)

1. **Centralize a URL base** em constante ou `appsettings`/variável de build (Debug vs Release).
2. Use **`System.Net.Http.HttpClient`** (ou `IHttpClientFactory` se injetar DI no `MauiProgram`).
3. Para JSON, use **`System.Text.Json`** ou Newtonsoft, alinhado aos exemplos do [api-contrato.md](api-contrato.md).
4. **Login:** guarde o token com segurança (por exemplo **`SecureStorage`** no MAUI), não em texto puro em `Preferences` se possível.
5. Em **toda** requisição autenticada:

```http
Authorization: Bearer <token retornado pelo POST /auth/login>
Content-Type: application/json
```

6. **Cadastro:** `POST /users` com `email` e `password` no corpo (ver contrato).
7. **Login:** `POST /auth/login` — resposta traz `token` e `user`.

Fluxo mínimo para validar integração:

1. `POST /users` → 201  
2. `POST /auth/login` → 200 + `token`  
3. `GET /products` com Bearer → 200 + `products` e `meta`

---

## 6. Endpoints que o app deve consumir (resumo)

Referência completa: **[api-contrato.md](api-contrato.md)**. Resumo operacional:

| Uso no app | Método e caminho |
|------------|------------------|
| Cadastro | `POST /users` |
| Login | `POST /auth/login` |
| Excluir conta (LGPD) | `DELETE /account` |
| Enviar URL da NFC-e | `POST /receipts` — resposta **202**; processamento é **assíncrono** (não espere o parse na mesma resposta) |
| Buscar produtos | `GET /products?q=&page=&per=` |
| Preços + outlier | `GET /products/:id/prices` |
| Listas | `GET/POST /shopping_lists`, `GET/PATCH/DELETE /shopping_lists/:id` |
| Itens da lista | `GET/POST …/shopping_lists/:id/items`, `PATCH/DELETE …/items/:id` |
| Onde comprar (ranking por lista) | `GET /shopping_lists/:id/store_rankings` |

Erros frequentes descritos no contrato: **401** (token inválido/ausente), **404** (recurso), **409** (ex.: mesma chave de NFC-e já cadastrada), **422** (validação em vários recursos).

---

## 7. Testar a API sem o app (curl)

Com Docker no ar e um e-mail/senha de teste:

```powershell
curl.exe -s -X POST http://localhost:3000/users -H "Content-Type: application/json" -d "{\"email\":\"dev@test.local\",\"password\":\"senhaSegura123\"}"
curl.exe -s -X POST http://localhost:3000/auth/login -H "Content-Type: application/json" -d "{\"email\":\"dev@test.local\",\"password\":\"senhaSegura123\"}"
```

Use o `token` da resposta:

```powershell
curl.exe -s -H "Authorization: Bearer COLE_O_TOKEN" http://localhost:3000/products
```

No repositório há também o script **`backend/api/script/e2e_api_smoke.sh`** (Linux/bash dentro do container) que percorre vários fluxos; útil para validar o backend após mudanças.

---

## 8. Ordem de trabalho no app

Ordem sugerida de integração (endpoints, payloads, fases): **[frontend-guia-api-e-ordem.md](frontend-guia-api-e-ordem.md)**.

Telas e UX em português: **[telas-do-app.md](telas-do-app.md)**.

---

## 9. Documentação técnica relacionada

| Ficheiro | Conteúdo |
|----------|------------|
| [api-contrato.md](api-contrato.md) | Contrato HTTP (payloads, códigos, regras) |
| [frontend-guia-api-e-ordem.md](frontend-guia-api-e-ordem.md) | **(PT)** Guia para o front: todos os endpoints, respostas e ordem de implementação |
| [schema-banco.md](schema-banco.md) | Modelo de dados e pipeline de recibos |
| [estrutura-repositorio.md](estrutura-repositorio.md) | Layout do monorepo |
| [backend/api/README.md](../backend/api/README.md) | Jobs, seeds, scripts úteis da API |

---

## 10. Problemas comuns

| Sintoma | O que verificar |
|---------|-----------------|
| App não conecta no emulador Android | URL deve ser **`10.0.2.2:3000`**, não `localhost` |
| App em celular não alcança o PC | Mesma rede, firewall, IP correto, porta 3000 aberta |
| Sempre 401 | Token ausente, expirado (tokens têm validade) ou header `Authorization` incorreto |
| POST /receipts retorna 409 | Chave da NFC-e já existe no sistema — tratar mensagem ao utilizador |
| `POST /auth/login` devolve **400** no PowerShell | O body JSON partiu-se (escapes em `curl -d "..."`). Usar `Invoke-RestMethod` com `ConvertTo-Json`, ou ficheiro + `curl --data-binary @ficheiro`, ou o script **`backend/api/script/smoke_endpoints_one_by_one.ps1`**. |
| Docker não sobe | Docker Desktop ligado; `docker compose ps`; ver logs: `docker compose logs api` |

---

*Última orientação: mantenha um único sítio no código (constante ou configuração de build) para a base URL da API, para alternar facilmente entre desenvolvimento (PC/emulador) e produção (HTTPS + domínio real) quando existir deploy.*
