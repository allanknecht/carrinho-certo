using System.Net.Http.Json;
using System.Net.Http.Headers;
using CarrinhoCerto.Models;
using System.Text.Json;

namespace CarrinhoCerto.Services;

public class ApiService
{
    private readonly HttpClient _httpClient;
    private const string BaseUrl = "http://10.156.23.70:3000";

    public ApiService()
    {
        _httpClient = new HttpClient();
    }

    private async Task SetAuthHeaderAsync()
    {
        var token = await SecureStorage.Default.GetAsync("auth_token");
        if (!string.IsNullOrEmpty(token))
        {
            _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        }
    }

    public async Task<(bool IsSuccess, string ErrorMessage)> RegisterUserAsync(string email, string password)
    {
        try
        {
            var request = new { email = email, password = password };
            var response = await _httpClient.PostAsJsonAsync($"{BaseUrl}/users", request);

            if (response.IsSuccessStatusCode)
            {
                return (true, string.Empty);
            }
            else
            {
                var errorContent = await response.Content.ReadAsStringAsync();
                return (false, "Erro ao criar cadastro. Verifique os dados.");
            }
        }
        catch (Exception ex)
        {
            return (false, $"Erro de conexão: {ex.Message}");
        }
    }

    public async Task<(bool IsSuccess, string ErrorMessage)> LoginAsync(string email, string password)
    {
        try
        {
            var request = new { email = email, password = password };
            var response = await _httpClient.PostAsJsonAsync($"{BaseUrl}/auth/login", request);

            if (response.IsSuccessStatusCode)
            {
                var result = await response.Content.ReadFromJsonAsync<LoginResponse>();
                if (result?.Token != null)
                {
                    await SecureStorage.Default.SetAsync("auth_token", result.Token);
                    return (true, string.Empty);
                }
            }

            return (false, "Credenciais inválidas");
        }
        catch (Exception ex)
        {
            return (false, $"Erro de conexão: {ex.Message}");
        }
    }

    public void Logout()
    {
        SecureStorage.Default.Remove("auth_token");
        _httpClient.DefaultRequestHeaders.Authorization = null;
    }

    public async Task<List<Product>> GetProductsAsync(string query = "", int page = 1)
    {
        await SetAuthHeaderAsync();
        var url = string.IsNullOrWhiteSpace(query)
            ? $"{BaseUrl}/products?page={page}"
            : $"{BaseUrl}/products?q={query}&page={page}";

        var response = await _httpClient.GetAsync(url);
        if (response.IsSuccessStatusCode)
        {
            var result = await response.Content.ReadFromJsonAsync<ProductListResponse>();
            return result?.Products ?? new List<Product>();
        }
        return new List<Product>();
    }

    public async Task<ProductPricesResponse?> GetProductPricesAsync(int productId)
    {
        await SetAuthHeaderAsync();
        var response = await _httpClient.GetAsync($"{BaseUrl}/products/{productId}/prices");

        if (response.IsSuccessStatusCode)
        {
            return await response.Content.ReadFromJsonAsync<ProductPricesResponse>();
        }
        return null;
    }

    public async Task<(bool IsSuccess, string Message)> SendReceiptUrlAsync(string urlParams)
    {
        try
        {
            await SetAuthHeaderAsync();
            var request = new { source_url = urlParams };
            var response = await _httpClient.PostAsJsonAsync($"{BaseUrl}/receipts", request);

            if (response.StatusCode == System.Net.HttpStatusCode.Accepted)
            {
                return (true, "Nota recebida; os preços podem demorar alguns segundos a aparecer.");
            }
            else if (response.StatusCode == System.Net.HttpStatusCode.Conflict)
            {
                return (false, "Esta nota já foi registada anteriormente.");
            }

            var conteudoErro = await response.Content.ReadAsStringAsync();
            return (false, $"Erro do Servidor ({(int)response.StatusCode}): {conteudoErro}");
        }
        catch (Exception ex)
        {
            return (false, $"Erro interno do App: {ex.Message}");
        }
    }

    public async Task<List<ShoppingList>> GetMyListsAsync()
    {
        try
        {
            await SetAuthHeaderAsync();
            var response = await _httpClient.GetAsync($"{BaseUrl}/shopping_lists");

            if (response.IsSuccessStatusCode)
            {
                var content = await response.Content.ReadAsStringAsync();
                System.Diagnostics.Debug.WriteLine($"[JSON RECEBIDO LISTAS] {content}");
                var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };

                var doc = JsonDocument.Parse(content);

                if (doc.RootElement.ValueKind == JsonValueKind.Array)
                {
                    return JsonSerializer.Deserialize<List<ShoppingList>>(content, options) ?? new List<ShoppingList>();
                }

                if (doc.RootElement.ValueKind == JsonValueKind.Object && doc.RootElement.TryGetProperty("shopping_lists", out var listElem))
                {
                    return JsonSerializer.Deserialize<List<ShoppingList>>(listElem.GetRawText(), options) ?? new List<ShoppingList>();
                }
            }
            else
            {
                System.Diagnostics.Debug.WriteLine($"[ERRO HTTP LISTAS] Status: {response.StatusCode}");
            }
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[ERRO FATAL API] {ex.Message}");
        }
        return new List<ShoppingList>();
    }

    public async Task<ShoppingList> CreateListAsync(string name)
    {
        try
        {
            await SetAuthHeaderAsync();

            var payload = new { name = name };

            var content = new StringContent(System.Text.Json.JsonSerializer.Serialize(payload), System.Text.Encoding.UTF8, "application/json");
            var response = await _httpClient.PostAsync($"{BaseUrl}/shopping_lists", content);

            if (response.IsSuccessStatusCode)
            {
                var responseContent = await response.Content.ReadAsStringAsync();
                var options = new System.Text.Json.JsonSerializerOptions { PropertyNameCaseInsensitive = true };

                var doc = System.Text.Json.JsonDocument.Parse(responseContent);
                if (doc.RootElement.ValueKind == System.Text.Json.JsonValueKind.Object && doc.RootElement.TryGetProperty("shopping_list", out var listElem))
                {
                    return System.Text.Json.JsonSerializer.Deserialize<ShoppingList>(listElem.GetRawText(), options);
                }

                return System.Text.Json.JsonSerializer.Deserialize<ShoppingList>(responseContent, options);
            }
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[ERRO CRIAR] {ex.Message}");
        }
        return null;
    }

    public async Task<bool> UpdateListNameAsync(int listId, string newName)
    {
        try
        {
            await SetAuthHeaderAsync();

            var payload = new { name = newName };
            var content = new StringContent(System.Text.Json.JsonSerializer.Serialize(payload), System.Text.Encoding.UTF8, "application/json");

            var response = await _httpClient.PatchAsync($"{BaseUrl}/shopping_lists/{listId}", content);

            if (!response.IsSuccessStatusCode)
            {
                response = await _httpClient.PutAsync($"{BaseUrl}/shopping_lists/{listId}", content);
            }

            return response.IsSuccessStatusCode;
        }
        catch
        {
            return false;
        }
    }

    public async Task<ListDetailsResponse> GetListDetailsAsync(int listId)
    {
        try
        {
            await SetAuthHeaderAsync();
            var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };

            var listResponse = await _httpClient.GetAsync($"{BaseUrl}/shopping_lists/{listId}");
            ShoppingList listInfo = null;
            if (listResponse.IsSuccessStatusCode)
            {
                var content = await listResponse.Content.ReadAsStringAsync();
                listInfo = JsonSerializer.Deserialize<ShoppingList>(content, options);
            }

            List<ListItem> itemsRaw = new List<ListItem>();
            var itemsResponse = await _httpClient.GetAsync($"{BaseUrl}/shopping_lists/{listId}/items");
            if (itemsResponse.IsSuccessStatusCode)
            {
                var content = await itemsResponse.Content.ReadAsStringAsync();
                var doc = JsonDocument.Parse(content);
                if (doc.RootElement.TryGetProperty("items", out var itemsElem))
                {
                    itemsRaw = JsonSerializer.Deserialize<List<ListItem>>(itemsElem.GetRawText(), options) ?? new List<ListItem>();
                }
            }

            List<ListItem> items = new List<ListItem>();
            foreach (var rawItem in itemsRaw)
            {
                if (rawItem.ProductId == null) continue;

                var existente = items.FirstOrDefault(i => i.ProductId == rawItem.ProductId);
                if (existente != null)
                {
                    double q1 = 1, q2 = 1;
                    double.TryParse(existente.QuantidadeRaw?.Replace(".000", ""), System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out q1);
                    double.TryParse(rawItem.QuantidadeRaw?.Replace(".000", ""), System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out q2);

                    existente.QuantidadeRaw = (q1 + q2).ToString(System.Globalization.CultureInfo.InvariantCulture);
                }
                else
                {
                    items.Add(rawItem);
                }
            }

            List<MarketPriceSummary> rankings = new List<MarketPriceSummary>();
            var totaisPorMercado = new Dictionary<string, decimal>();
            var contagemProdutosPorMercado = new Dictionary<string, int>();

            int totalDeProdutosDiferentesNaLista = items.Count;

            if (items.Any())
            {
                foreach (var item in items)
                {
                    if (item.ProductId.HasValue)
                    {
                        var pricesResponse = await GetProductPricesAsync(item.ProductId.Value);

                        if (pricesResponse != null)
                        {
                            item.ProductName = pricesResponse.Product?.DisplayName;

                            double qtd = 1.0;
                            if (!string.IsNullOrEmpty(item.QuantidadeRaw))
                            {
                                double.TryParse(item.QuantidadeRaw.Replace(".000", ""), System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out qtd);
                            }

                            if (pricesResponse.Stores != null && pricesResponse.Stores.Any())
                            {
                                var menorPrecoProduto = pricesResponse.Stores
                                    .Select(s => decimal.TryParse(s.UnitPrice, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out var p) ? p : 0)
                                    .Where(p => p > 0)
                                    .OrderBy(p => p)
                                    .FirstOrDefault();

                                item.EstimatedPrice = menorPrecoProduto;

                                var lojasValidasProduto = pricesResponse.Stores
                                    .GroupBy(s => !string.IsNullOrEmpty(s.Nome) ? s.Nome : $"Mercado {s.StoreId}")
                                    .Select(g => new {
                                        StoreName = g.Key,
                                        LowestPrice = g.Select(s => decimal.TryParse(s.UnitPrice, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out var p) ? p : 0).Where(p => p > 0).Min()
                                    }).Where(x => x.LowestPrice > 0);

                                foreach (var store in lojasValidasProduto)
                                {
                                    if (!totaisPorMercado.ContainsKey(store.StoreName))
                                    {
                                        totaisPorMercado[store.StoreName] = 0;
                                        contagemProdutosPorMercado[store.StoreName] = 0;
                                    }

                                    totaisPorMercado[store.StoreName] += (store.LowestPrice * (decimal)qtd);
                                    contagemProdutosPorMercado[store.StoreName]++;
                                }
                            }
                        }
                    }
                }
            }

            foreach (var kvp in totaisPorMercado)
            {
                if (contagemProdutosPorMercado[kvp.Key] == totalDeProdutosDiferentesNaLista)
                {
                    rankings.Add(new MarketPriceSummary
                    {
                        MarketName = kvp.Key,
                        TotalPrice = kvp.Value
                    });
                }
            }

            rankings = rankings.OrderBy(r => r.TotalPrice).ToList();

            if (listInfo != null)
            {
                listInfo.ItemCount = items.Count;
            }

            return new ListDetailsResponse
            {
                ListInfo = listInfo ?? new ShoppingList { Name = "Minha Lista", ItemCount = items.Count },
                Items = items,
                BestMarket = rankings.FirstOrDefault(),
                TopMarkets = rankings.Take(3).ToList()
            };
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[ERRO DETALHES] {ex.Message}");
            return null;
        }
    }

    public async Task<bool> AddProductToListAsync(int listId, int productId, int quantity = 1)
    {
        try
        {
            await SetAuthHeaderAsync();

            var payload = new
            {
                product_canonical_id = productId,
                quantidade = quantity.ToString()
            };

            var json = System.Text.Json.JsonSerializer.Serialize(payload);
            var content = new StringContent(json, System.Text.Encoding.UTF8, "application/json");

            var response = await _httpClient.PostAsync($"{BaseUrl}/shopping_lists/{listId}/items", content);

            return response.IsSuccessStatusCode;
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[ERRO AO ADICIONAR ITEM] {ex.Message}");
            return false;
        }
    }

    public async Task<bool> DeleteListAsync(int listId)
    {
        try
        {
            await SetAuthHeaderAsync();
            var response = await _httpClient.DeleteAsync($"{BaseUrl}/shopping_lists/{listId}");

            return response.IsSuccessStatusCode;
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[ERRO AO EXCLUIR] {ex.Message}");
            return false;
        }
    }

    public async Task<bool> RemoveListItemAsync(int listId, int itemId)
    {
        try
        {
            await SetAuthHeaderAsync();
            var response = await _httpClient.DeleteAsync($"{BaseUrl}/shopping_lists/{listId}/items/{itemId}");
            return response.IsSuccessStatusCode;
        }
        catch
        {
            return false;
        }
    }
}