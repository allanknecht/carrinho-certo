#!/usr/bin/env bash
# Smoke E2E: todos os endpoints públicos da API (container: BASE=http://127.0.0.1:3000)
set -euo pipefail
BASE="${BASE:-http://127.0.0.1:3000}"
FAIL=0
ok() { echo "OK  $*"; }
bad() { echo "FAIL $*"; FAIL=1; }

echo "=== 1) GET /up ==="
code=$(curl -s -o /tmp/up.body -w "%{http_code}" "$BASE/up")
grep -q "200\|green" /tmp/up.body || true
[[ "$code" == "200" ]] && ok "/up -> $code" || bad "/up -> $code"

echo "=== 2) POST /users ==="
EMAIL="e2e_$(date +%s)@smoke.test"
R=$(curl -s -w "\n%{http_code}" -X POST "$BASE/users" -H "Content-Type: application/json" \
  -d "$(ruby -rjson -e 'print JSON.generate({email: ARGV[0], password: "secret12345"})' "$EMAIL")")
CODE=$(echo "$R" | tail -1)
BODY=$(echo "$R" | sed '$d')
[[ "$CODE" == "201" ]] && ok "POST /users $CODE" || bad "POST /users $CODE $BODY"

echo "=== 3) POST /auth/login (senha errada) ==="
R=$(curl -s -w "\n%{http_code}" -X POST "$BASE/auth/login" -H "Content-Type: application/json" \
  -d "$(ruby -rjson -e 'print JSON.generate({email: ARGV[0], password: "wrong"})' "$EMAIL")")
CODE=$(echo "$R" | tail -1)
[[ "$CODE" == "401" ]] && ok "login errado $CODE" || bad "login errado $CODE"

echo "=== 4) POST /auth/login ==="
TOKEN=$(curl -s -X POST "$BASE/auth/login" -H "Content-Type: application/json" \
  -d "$(ruby -rjson -e 'print JSON.generate({email: ARGV[0], password: "secret12345"})' "$EMAIL")" | ruby -rjson -e 'print JSON.parse(STDIN.read)["token"]')
[[ -n "$TOKEN" ]] && ok "token obtido" || bad "sem token"

echo "=== 5) GET /products sem auth ==="
CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/products")
[[ "$CODE" == "401" ]] && ok "GET /products sem auth $CODE" || bad "esperado 401, got $CODE"

AUTH=( -H "Authorization: Bearer $TOKEN" )

echo "=== 6) GET /products ==="
R=$(curl -s "${AUTH[@]}" "$BASE/products?per=10")
PID=$(echo "$R" | ruby -rjson -e 'j=JSON.parse(STDIN.read); puts j["products"][0]["id"] if j["products"].any?')
[[ -n "${PID:-}" ]] && ok "GET /products produto id=$PID" || bad "GET /products sem produtos (rode db:seed)"

echo "=== 7) GET /products/999999/prices (inexistente) ==="
CODE=$(curl -s -o /dev/null -w "%{http_code}" "${AUTH[@]}" "$BASE/products/999999/prices")
[[ "$CODE" == "404" ]] && ok "prices 404 $CODE" || bad "prices inexistente $CODE"

echo "=== 8) GET /products/:id/prices ==="
R=$(curl -s "${AUTH[@]}" "$BASE/products/$PID/prices")
echo "$R" | ruby -rjson -e 'j=JSON.parse(STDIN.read); raise "sem stores" unless j.key?("stores"); raise "sem product" unless j.key?("product")'
ok "GET /products/$PID/prices JSON completo"

echo "=== 9) POST /shopping_lists ==="
R=$(curl -s -w "\n%{http_code}" -X POST "$BASE/shopping_lists" "${AUTH[@]}" -H "Content-Type: application/json" \
  -d '{"name":"Lista smoke"}')
CODE=$(echo "$R" | tail -1)
LID=$(echo "$R" | sed '$d' | ruby -rjson -e 'print JSON.parse(STDIN.read)["id"]')
[[ "$CODE" == "201" && -n "$LID" ]] && ok "lista id=$LID" || bad "criar lista $CODE"

echo "=== 10) POST /shopping_lists/:id/items (com product) ==="
R=$(curl -s -w "\n%{http_code}" -X POST "$BASE/shopping_lists/$LID/items" "${AUTH[@]}" -H "Content-Type: application/json" \
  -d "$(ruby -rjson -e 'print JSON.generate({product_canonical_id: ARGV[0].to_i, quantidade: "2", label: "linha e2e"})' "$PID")")
CODE=$(echo "$R" | tail -1)
IBODY=$(echo "$R" | sed '$d')
ITEM_ID=$(echo "$IBODY" | ruby -rjson -e 'print JSON.parse(STDIN.read)["id"]' 2>/dev/null || true)
[[ "$CODE" == "201" && -n "${ITEM_ID:-}" ]] && ok "item criado id=$ITEM_ID $CODE" || bad "item $CODE $IBODY"

echo "=== 10b) GET /shopping_lists/:id (show com items) ==="
CODE=$(curl -s -o /dev/null -w "%{http_code}" "${AUTH[@]}" "$BASE/shopping_lists/$LID")
[[ "$CODE" == "200" ]] && ok "GET show lista $CODE" || bad "GET show $CODE"

echo "=== 10c) GET /shopping_lists/:id/items (index) ==="
CODE=$(curl -s -o /dev/null -w "%{http_code}" "${AUTH[@]}" "$BASE/shopping_lists/$LID/items")
[[ "$CODE" == "200" ]] && ok "GET items index $CODE" || bad "GET items $CODE"

echo "=== 10d) PATCH /items/:id ==="
CODE=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH "$BASE/shopping_lists/$LID/items/$ITEM_ID" "${AUTH[@]}" -H "Content-Type: application/json" \
  -d '{"quantidade":"3","label":"linha patch"}')
[[ "$CODE" == "200" ]] && ok "PATCH item $CODE" || bad "PATCH item $CODE"

echo "=== 11) GET /shopping_lists/:id/store_rankings ==="
CODE=$(curl -s -o /dev/null -w "%{http_code}" "${AUTH[@]}" "$BASE/shopping_lists/$LID/store_rankings")
R=$(curl -s "${AUTH[@]}" "$BASE/shopping_lists/$LID/store_rankings")
echo "$R" | ruby -rjson -e 'j=JSON.parse(STDIN.read); raise "sem stores" unless j.key?("stores"); raise "sem lines" unless j.key?("lines")'
[[ "$CODE" == "200" ]] && ok "store_rankings $CODE" || bad "store_rankings $CODE"

echo "=== 12) PATCH /shopping_lists/:id ==="
CODE=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH "$BASE/shopping_lists/$LID" "${AUTH[@]}" -H "Content-Type: application/json" -d '{"name":"Lista renomeada"}')
[[ "$CODE" == "200" ]] && ok "PATCH lista $CODE" || bad "PATCH lista $CODE"

echo "=== 13) GET /shopping_lists (index) ==="
CODE=$(curl -s -o /dev/null -w "%{http_code}" "${AUTH[@]}" "$BASE/shopping_lists")
[[ "$CODE" == "200" ]] && ok "index listas $CODE" || bad "index $CODE"

echo "=== 13b) DELETE /shopping_lists/:id/items/:id ==="
CODE=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$BASE/shopping_lists/$LID/items/$ITEM_ID" "${AUTH[@]}")
[[ "$CODE" == "204" ]] && ok "DELETE item $CODE" || bad "DELETE item $CODE"

echo "=== 13c) DELETE /shopping_lists/:id ==="
CODE=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$BASE/shopping_lists/$LID" "${AUTH[@]}")
[[ "$CODE" == "204" ]] && ok "DELETE lista $CODE" || bad "DELETE lista $CODE"

echo "=== 14) POST /receipts URL real SVRS ==="
NFCE_URL="https://dfe-portal.svrs.rs.gov.br/Dfe/QrCodeNFce?p=43260352932793000180650040000458781305092704|2|1|1|884FCC1C2C6D808E592728FFB256321232106483"
R=$(curl -s -w "\n%{http_code}" -X POST "$BASE/receipts" "${AUTH[@]}" -H "Content-Type: application/json" \
  -d "$(ruby -rjson -e 'print JSON.generate({source_url: ARGV[0]})' "$NFCE_URL")")
CODE=$(echo "$R" | tail -1)
BODY=$(echo "$R" | sed '$d')
RID=$(echo "$BODY" | ruby -rjson -e 'print JSON.parse(STDIN.read)["id"]' 2>/dev/null || true)
if [[ "$CODE" == "202" && -n "${RID:-}" ]]; then
  ok "receipt enfileirado id=$RID (aceite e fila)"
  echo "    (aguardar ProcessReceiptJob async...)"
  sleep 12
  if RAILS_ENV=development bin/rails runner "r=Receipt.find($RID); exit(1) unless r.status=='done'; exit(1) unless r.receipt_item_raws.count>=1" 2>/dev/null; then
    ok "ProcessReceiptJob: receipt $RID done com linhas"
  else
    bad "receipt $RID nao processado"
  fi
elif [[ "$CODE" == "409" ]]; then
  ok "POST /receipts 409 — chave ja existia na BD (re-run / outro teste); regra anti-duplicata OK"
else
  bad "POST /receipts inesperado $CODE $BODY"
fi

echo "=== 15) POST /receipts duplicado (409) ==="
R=$(curl -s -w "\n%{http_code}" -X POST "$BASE/receipts" "${AUTH[@]}" -H "Content-Type: application/json" \
  -d "$(ruby -rjson -e 'print JSON.generate({source_url: ARGV[0]})' "$NFCE_URL")")
CODE=$(echo "$R" | tail -1)
[[ "$CODE" == "409" ]] && ok "duplicate chave 409" || bad "esperado 409 duplicate, got $CODE $(echo "$R"|sed '$d')"

echo "=== 16) DELETE /account (utilizador LGPD dedicado) ==="
EMAIL2="lgpd_$(date +%s)@smoke.test"
curl -s -X POST "$BASE/users" -H "Content-Type: application/json" \
  -d "$(ruby -rjson -e 'print JSON.generate({email: ARGV[0], password: "secret12345"})' "$EMAIL2")" >/dev/null
TOK2=$(curl -s -X POST "$BASE/auth/login" -H "Content-Type: application/json" \
  -d "$(ruby -rjson -e 'print JSON.generate({email: ARGV[0], password: "secret12345"})' "$EMAIL2")" | ruby -rjson -e 'print JSON.parse(STDIN.read)["token"]')
CODE=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$BASE/account" -H "Authorization: Bearer $TOK2")
[[ "$CODE" == "204" ]] && ok "DELETE /account $CODE" || bad "DELETE /account $CODE"
CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/auth/login" -H "Content-Type: application/json" \
  -d "$(ruby -rjson -e 'print JSON.generate({email: ARGV[0], password: "secret12345"})' "$EMAIL2")")
[[ "$CODE" == "401" ]] && ok "login apos delete $CODE" || bad "login apos delete $CODE"

exit "$FAIL"
