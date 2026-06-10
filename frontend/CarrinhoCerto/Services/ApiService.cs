using System.Net.Http.Json;
using System.Net.Http.Headers;
using CarrinhoCerto.Models;
using System.Text.Json;
using System.Globalization;

namespace CarrinhoCerto.Services;

public class ApiService
{
    private static readonly HttpClient SharedHttpClient = new()
    {
        Timeout = TimeSpan.FromSeconds(30)
    };

    public static ApiService Shared { get; } = new();

    private readonly HttpClient _httpClient;
    private const string BaseUrl = "http://192.168.0.34:3000";

    public ApiService()
    {
        _httpClient = SharedHttpClient;
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
                    if (!string.IsNullOrEmpty(result.User?.Email))
                    {
                        await SecureStorage.Default.SetAsync("user_email", result.User.Email);
                    }
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
        SecureStorage.Default.Remove("user_email");
        _httpClient.DefaultRequestHeaders.Authorization = null;
    }

    public async Task<UserProfile?> GetCurrentUserAsync()
    {
        try
        {
            var cached = await SecureStorage.Default.GetAsync("user_email");
            if (!string.IsNullOrEmpty(cached))
            {
                return new UserProfile { Email = cached };
            }

            await SetAuthHeaderAsync();
            var response = await _httpClient.GetAsync($"{BaseUrl}/account");
            if (!response.IsSuccessStatusCode) return null;

            var result = await response.Content.ReadFromJsonAsync<AccountResponse>();
            if (!string.IsNullOrEmpty(result?.User?.Email))
            {
                await SecureStorage.Default.SetAsync("user_email", result.User.Email);
            }
            return result?.User;
        }
        catch
        {
            return null;
        }
    }

    public async Task<List<PriceHighlight>> GetPriceHighlightsAsync(int limit = 3)
    {
        try
        {
            await SetAuthHeaderAsync();
            var response = await _httpClient.GetAsync($"{BaseUrl}/products/highlights?limit={limit}");
            if (!response.IsSuccessStatusCode) return new List<PriceHighlight>();

            var result = await response.Content.ReadFromJsonAsync<PriceHighlightsResponse>();
            return result?.Highlights ?? new List<PriceHighlight>();
        }
        catch
        {
            return new List<PriceHighlight>();
        }
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

            var listTask = _httpClient.GetAsync($"{BaseUrl}/shopping_lists/{listId}");
            var rankingsTask = _httpClient.GetAsync($"{BaseUrl}/shopping_lists/{listId}/store_rankings");
            await Task.WhenAll(listTask, rankingsTask);

            ShoppingList? listInfo = null;
            if (listTask.Result.IsSuccessStatusCode)
            {
                var content = await listTask.Result.Content.ReadAsStringAsync();
                listInfo = JsonSerializer.Deserialize<ShoppingList>(content, options);
            }

            var items = ConsolidateListItems(listInfo?.Items ?? new List<ListItem>());

            var rankings = new List<MarketPriceSummary>();
            if (rankingsTask.Result.IsSuccessStatusCode)
            {
                var ranking = await rankingsTask.Result.Content.ReadFromJsonAsync<RankingResponse>(options);
                rankings = ranking?.Stores?
                    .Where(s => s.LinesMissingPrice == 0)
                    .OrderBy(s => s.TotalFinal)
                    .ToList() ?? new List<MarketPriceSummary>();
            }

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

    private static List<ListItem> ConsolidateListItems(IEnumerable<ListItem> itemsRaw)
    {
        var items = new List<ListItem>();
        foreach (var rawItem in itemsRaw)
        {
            if (rawItem.ProductId == null)
            {
                items.Add(rawItem);
                continue;
            }

            var existente = items.FirstOrDefault(i => i.ProductId == rawItem.ProductId);
            if (existente != null)
            {
                double q1 = 1, q2 = 1;
                double.TryParse(existente.QuantidadeRaw?.Replace(".000", ""), NumberStyles.Any, CultureInfo.InvariantCulture, out q1);
                double.TryParse(rawItem.QuantidadeRaw?.Replace(".000", ""), NumberStyles.Any, CultureInfo.InvariantCulture, out q2);
                existente.QuantidadeRaw = (q1 + q2).ToString(CultureInfo.InvariantCulture);
            }
            else
            {
                items.Add(rawItem);
            }
        }
        return items;
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