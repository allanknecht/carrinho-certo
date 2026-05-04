#Requires -Version 5.1
<#
.SYNOPSIS
  Chama cada endpoint HTTP da API um a um (Windows / PowerShell).

.DESCRIPTION
  No PowerShell, curl -d "{\"email\":...}" partilha o JSON e a API pode responder 400 (ParseError).
  Este script grava o body em UTF-8 sem BOM e usa curl.exe --data-binary "@ficheiro".

.PARAMETER BaseUrl
  Por defeito http://127.0.0.1:3000

.EXAMPLE
  cd backend\api
  .\script\smoke_endpoints_one_by_one.ps1
#>
param(
  [string] $BaseUrl = "http://127.0.0.1:3000"
)

$ErrorActionPreference = "Stop"

function Write-JsonUtf8NoBom([string] $Path, [hashtable] $Object) {
  $json = ($Object | ConvertTo-Json -Compress)
  [System.IO.File]::WriteAllText($Path, $json, [System.Text.UTF8Encoding]::new($false))
}

function Invoke-JsonPost([string] $Url, [hashtable] $Body, [hashtable] $Headers = @{}) {
  $tmp = [System.IO.Path]::GetTempFileName()
  try {
    Write-JsonUtf8NoBom $tmp $Body
    $curlArgs = @(
      "-s", "-w", "`nHTTP:%{http_code}`n",
      "-X", "POST", $Url,
      "-H", "Content-Type: application/json; charset=utf-8"
    )
    foreach ($k in $Headers.Keys) {
      $curlArgs += "-H"
      $curlArgs += "$k`: $($Headers[$k])"
    }
    $curlArgs += "--data-binary"
    $curlArgs += "@$tmp"
    & curl.exe @curlArgs
  }
  finally {
    Remove-Item $tmp -ErrorAction SilentlyContinue
  }
}

function ExpectHttp([string] $Output, [string[]] $Allowed) {
  $m = [regex]::Match($Output, "HTTP:(\d+)")
  if (-not $m.Success) { throw "Resposta sem linha HTTP:nnn (curl -w)" }
  $code = $m.Groups[1].Value
  if ($Allowed -notcontains $code) {
    throw "HTTP $code (esperado um de: $($Allowed -join ', '))"
  }
  Write-Host "  -> HTTP $code OK" -ForegroundColor Green
}

function Banner([string] $n, [string] $msg) {
  Write-Host ""
  Write-Host "[$n] $msg" -ForegroundColor Cyan
}

$email = "smoke_ps_{0}@test.local" -f [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$pass = "secret12345"

Banner "1" "GET /up"
$out = curl.exe -s -w "`nHTTP:%{http_code}`n" "$BaseUrl/up"
ExpectHttp $out @("200")

Banner "2" "POST /users"
$out = Invoke-JsonPost "$BaseUrl/users" @{ email = $email; password = $pass }
Write-Host (($out -split "`nHTTP:")[0])
ExpectHttp $out @("201")

Banner "3" "POST /auth/login (senha errada) -> 401"
$out = Invoke-JsonPost "$BaseUrl/auth/login" @{ email = $email; password = "wrong" }
Write-Host (($out -split "`nHTTP:")[0])
ExpectHttp $out @("401")

Banner "4" "POST /auth/login (ok)"
$out = Invoke-JsonPost "$BaseUrl/auth/login" @{ email = $email; password = $pass }
ExpectHttp $out @("200")
$token = (($out -split "`nHTTP:")[0] | ConvertFrom-Json).token
if (-not $token) { throw "Sem token" }
Write-Host "  -> token obtido" -ForegroundColor Green

Banner "5" "GET /products sem auth -> 401"
$out = curl.exe -s -w "`nHTTP:%{http_code}`n" "$BaseUrl/products"
ExpectHttp $out @("401")

Banner "6" "GET /products?per=1"
$out = curl.exe -s -w "`nHTTP:%{http_code}`n" -H "Authorization: Bearer $token" "$BaseUrl/products?per=1"
ExpectHttp $out @("200")
$productId = (($out -split "`nHTTP:")[0] | ConvertFrom-Json).products[0].id
Write-Host "  -> product id = $productId" -ForegroundColor Green

Banner "7" "GET /products/999999/prices -> 404"
$out = curl.exe -s -w "`nHTTP:%{http_code}`n" -H "Authorization: Bearer $token" "$BaseUrl/products/999999/prices"
Write-Host (($out -split "`nHTTP:")[0])
ExpectHttp $out @("404")

Banner "8" "GET /products/{id}/prices"
$out = curl.exe -s -w "`nHTTP:%{http_code}`n" -H "Authorization: Bearer $token" "$BaseUrl/products/$productId/prices"
ExpectHttp $out @("200")
$pr = ($out -split "`nHTTP:")[0] | ConvertFrom-Json
Write-Host "  -> keys: $($pr.PSObject.Properties.Name -join ', '); stores: $($pr.stores.Count)" -ForegroundColor Green

$authH = @{ Authorization = "Bearer $token" }

Banner "9" "POST /shopping_lists"
$out = Invoke-JsonPost "$BaseUrl/shopping_lists" @{ name = "Smoke PS" } $authH
ExpectHttp $out @("201")
$listId = (($out -split "`nHTTP:")[0] | ConvertFrom-Json).id
Write-Host "  -> list id = $listId" -ForegroundColor Green

Banner "10" "GET /shopping_lists"
$out = curl.exe -s -w "`nHTTP:%{http_code}`n" -H "Authorization: Bearer $token" "$BaseUrl/shopping_lists"
ExpectHttp $out @("200")

Banner "11" "GET /shopping_lists/{id}"
$out = curl.exe -s -w "`nHTTP:%{http_code}`n" -H "Authorization: Bearer $token" "$BaseUrl/shopping_lists/$listId"
ExpectHttp $out @("200")

Banner "12" "POST /shopping_lists/{id}/items"
$out = Invoke-JsonPost "$BaseUrl/shopping_lists/$listId/items" @{
  product_canonical_id = $productId
  quantidade           = "2"
} $authH
ExpectHttp $out @("201")
$itemId = (($out -split "`nHTTP:")[0] | ConvertFrom-Json).id
Write-Host "  -> item id = $itemId" -ForegroundColor Green

Banner "13" "GET /shopping_lists/{id}/items"
$out = curl.exe -s -w "`nHTTP:%{http_code}`n" -H "Authorization: Bearer $token" "$BaseUrl/shopping_lists/$listId/items"
ExpectHttp $out @("200")

Banner "14" "PATCH /shopping_lists/{id}/items/{id}"
$tmp = [System.IO.Path]::GetTempFileName()
try {
  Write-JsonUtf8NoBom $tmp @{ quantidade = "3" }
  $out = curl.exe -s -w "`nHTTP:%{http_code}`n" -X PATCH "$BaseUrl/shopping_lists/$listId/items/$itemId" `
    -H "Authorization: Bearer $token" -H "Content-Type: application/json; charset=utf-8" `
    --data-binary "@$tmp"
  ExpectHttp $out @("200")
}
finally { Remove-Item $tmp -ErrorAction SilentlyContinue }

Banner "15" "GET /shopping_lists/{id}/store_rankings"
$out = curl.exe -s -w "`nHTTP:%{http_code}`n" -H "Authorization: Bearer $token" "$BaseUrl/shopping_lists/$listId/store_rankings"
ExpectHttp $out @("200")

Banner "16" "PATCH /shopping_lists/{id}"
$tmp = [System.IO.Path]::GetTempFileName()
try {
  Write-JsonUtf8NoBom $tmp @{ name = "Renomeada PS" }
  $out = curl.exe -s -w "`nHTTP:%{http_code}`n" -X PATCH "$BaseUrl/shopping_lists/$listId" `
    -H "Authorization: Bearer $token" -H "Content-Type: application/json; charset=utf-8" `
    --data-binary "@$tmp"
  ExpectHttp $out @("200")
}
finally { Remove-Item $tmp -ErrorAction SilentlyContinue }

Banner "17" "DELETE /shopping_lists/{id}/items/{id}"
$out = curl.exe -s -w "`nHTTP:%{http_code}`n" -X DELETE -H "Authorization: Bearer $token" "$BaseUrl/shopping_lists/$listId/items/$itemId"
ExpectHttp $out @("204")

Banner "18" "DELETE /shopping_lists/{id}"
$out = curl.exe -s -w "`nHTTP:%{http_code}`n" -X DELETE -H "Authorization: Bearer $token" "$BaseUrl/shopping_lists/$listId"
ExpectHttp $out @("204")

Banner "19" "POST /receipts (202 ou 409)"
$url = "https://dfe-portal.svrs.rs.gov.br/Dfe/QrCodeNFce?p=43260352932793000180650040000458781305092704|2|1|1|884FCC1C2C6D808E592728FFB256321232106483"
$out = Invoke-JsonPost "$BaseUrl/receipts" @{ source_url = $url } $authH
Write-Host (($out -split "HTTP:")[0].Trim())
$m = [regex]::Match($out, "HTTP:(\d+)")
if (-not $m.Success) { throw "Sem HTTP code no output do curl" }
$rc = $m.Groups[1].Value
if ($rc -notin @("202", "409")) { throw "HTTP $rc (esperado 202 ou 409)" }
Write-Host "  -> HTTP $rc OK" -ForegroundColor Green

$delEmail = "smoke_del_{0}@test.local" -f [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
Banner "20" "DELETE /account"
Invoke-JsonPost "$BaseUrl/users" @{ email = $delEmail; password = $pass } | Out-Null
$lo = Invoke-JsonPost "$BaseUrl/auth/login" @{ email = $delEmail; password = $pass }
$delTok = (($lo -split "`nHTTP:")[0] | ConvertFrom-Json).token
$out = curl.exe -s -w "`nHTTP:%{http_code}`n" -X DELETE "$BaseUrl/account" -H "Authorization: Bearer $delTok"
ExpectHttp $out @("204")

Banner "21" "POST /auth/login apos delete -> 401"
$out = Invoke-JsonPost "$BaseUrl/auth/login" @{ email = $delEmail; password = $pass }
ExpectHttp $out @("401")

Write-Host ""
Write-Host "Concluido: 21 passos." -ForegroundColor Green
Write-Host "Utilizador $email permaneceu na BD." -ForegroundColor DarkGray
