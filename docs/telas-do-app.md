# Telas do aplicativo – Carrinho Certo

> **English readers:** Screen inventory in Portuguese. For API behavior (receipts, auth), see [api-contrato.md](api-contrato.md).

Este documento lista as **telas necessárias** para o app mobile (front-end), alinhadas aos requisitos e fluxos descritos em [objetivos-requisitos-casos-de-uso.md](objetivos-requisitos-casos-de-uso.md).

---

## Visão geral

As telas estão agrupadas por **fluxo** e **área** do app. Itens marcados como *opcional* ou *futuro* podem ser deixados para uma segunda versão conforme prioridade do projeto.

---

## 1. Autenticação

| Tela | Descrição | Requisito |
|------|-----------|-----------|
| **Login** | Identificação por e-mail (e senha ou método definido). Acesso ao app após autenticação. | RF01 |
| **Cadastro** | Criação de nova conta (e-mail e dados mínimos). Após cadastro, envio de e-mail para confirmação. | RF01 |
| **Confirmação de e-mail** | Tela ou fluxo em que o usuário confirma o e-mail (link recebido por e-mail ou código informado no app). Necessário para ativar a conta e permitir login completo. | RF01 |
| **Recuperar senha** | Solicitação de redefinição de senha por e-mail. | *Opcional* |

---

## 2. Início / Navegação

| Tela | Descrição | Requisito |
|------|-----------|-----------|
| **Home / Início** | Tela principal após o login. Pode reunir atalhos: enviar nota, minhas listas, buscar produto. Ou servir como container da navegação (abas ou menu inferior). | — |

---

## 3. Envio de nota (NFC-e)

| Tela | Descrição | Requisito |
|------|-----------|-----------|
| **Enviar nota** | Permite escanear o QR da NFC-e (câmera) ou colar a URL/código da nota. Botão para enviar ao backend. | RF02 |
| **Confirmação / Status** | Após envio: feedback apenas de que a nota foi **enviada** com sucesso. O usuário não recebe informação sobre processamento ou conclusão do processamento. | RF02, RF03 |

---

## 4. Produtos e preços

| Tela | Descrição | Requisito |
|------|-----------|-----------|
| **Buscar produto** | Busca por **produto específico** (nome, categoria) ou a mesma busca restrita a um **mercado** escolhido no filtro. Na **listagem**: apenas **menor preço (relevante)** e **preço alternativo** por produto. Não há tela "por mercado" com notas ou detalhes do mercado; o mercado é apenas filtro da busca. | RF07 |
| **Detalhe do produto** | Ao abrir o produto: **mais informações** — nome, preço relevante e **histórico completo** por mercado, filtro por período (últimos 7 dias, 30 dias) e por mercado. Preços muito abaixo do normal com destaque e disclaimer. O usuário **não** vê quantidade de notas nem telas dedicadas a cada mercado. | RF07, RF08 |

*O mesmo padrão de listagem (menor preço + alternativo) é usado na tela "Adicionar item à lista" (item 5), podendo reutilizar o mesmo componente ou fluxo de busca.*

---

## 5. Listas de compras

| Tela | Descrição | Requisito |
|------|-----------|-----------|
| **Minhas listas** | Listagem das listas do usuário (nome, quantidade de itens). Ação: **botão "Nova lista"** que cria uma lista vazia e abre direto a tela dessa lista (dentro dela). Toque em uma lista existente para abrir. | RF09 |
| **Detalhe da lista** | **No topo:** nome da lista (padrão "Nova lista (1)", "Nova lista (2)" etc.; toque no nome para editar se quiser). Abaixo: itens (produto ou descrição livre, quantidade), opção de **remover**, botão "Adicionar item". Para cada produto: os 3 mercados com menor preço. Bloco "onde é melhor comprar" (mercado sugerido e total). | RF09, RF10 |
| **Adicionar item à lista** | Tela separada com **caixa de pesquisa** (pode ser bem parecida à de "Buscar produto", item 4): conforme a pessoa digita, a lista de resultados atualiza dinamicamente. Por produto: apenas **menor preço (relevante)** e **preço alternativo**. Usuário escolhe o produto (ou item de texto livre), define quantidade e adiciona; em seguida volta para a tela da lista (dentro dela). | RF09 |

*Edição de itens (remover) e opção de texto livre ficam no detalhe da lista; adicionar itens do catálogo é pela tela "Adicionar item à lista".*

---

## 6. Conta e configurações

| Tela | Descrição | Requisito |
|------|-----------|-----------|
| **Conta / Perfil** | Dados do usuário (e-mail). Pode incluir opções: alterar senha, notificações. | — |
| **Excluir conta** | Fluxo para solicitar exclusão de conta e dos dados que identifiquem o usuário (LGPD). Confirmação explícita; após exclusão, retorno à tela de login. | RF11 |
| **Sair** | Encerrar sessão e retornar à tela de login. | — |

---

## 7. Futuro - Não fazer pro MVP

| Tela | Descrição | Requisito |
|------|-----------|-----------|
| **Alertas de preço** | Configuração de alertas por produto (ex.: avisar quando preço estiver muito abaixo do normal ou abaixo de um valor). Lista de alertas ativos. | *price_alerts* (futuro) |

---

## Resumo por prioridade

| Prioridade | Telas |
|------------|--------|
| **MVP** | Login, Cadastro, Confirmação de e-mail, Home, Enviar nota, Confirmação/Status, Buscar produto, Detalhe do produto, Minhas listas, Detalhe da lista (com "onde comprar"), Adicionar item à lista (tela separada com busca dinâmica), Conta, Excluir conta, Sair |
| **Opcional** | Recuperar senha |
| **Segundo momento** | Notas enviadas (lista das notas já enviadas pelo usuário) |
| **Futuro** | Alertas de preço |

---

## Navegação sugerida (referência)

- **Abas ou menu inferior:** Início | Listas | Produtos (busca) | Conta  
- **Início:** botão "Enviar nota" em destaque; atalhos para última lista ou busca.  
- **Enviar nota:** acessível a partir da Home ou de um botão flutuante.  
- **Onde comprar:** bloco fixo no detalhe da lista (não é tela separada).

A estrutura final de navegação fica a critério do design do app; o importante é cobrir as telas listadas acima para atender aos requisitos do projeto.
