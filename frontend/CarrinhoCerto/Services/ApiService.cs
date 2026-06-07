using System.Net.Http.Json;
using System.Net.Http.Headers;
using CarrinhoCerto.Models;
using System.Text.Json;

namespace CarrinhoCerto.Services;

public class ApiService
{
    private readonly HttpClient _httpClient;
    private const string BaseUrl = "http://192.168.3.14:3000";

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
                System.Diagnostics.Debug.WriteLine($"[JSON DAS LISTAS] {content}");

                var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
                var wrapper = JsonSerializer.Deserialize<ShoppingListsWrapper>(content, options);
                return wrapper?.ShoppingLists ?? new List<ShoppingList>();
            }
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[ERRO AO LER LISTAS] {ex.Message}");
        }
        return new List<ShoppingList>();
    }

    public async Task<ShoppingList> CreateListAsync(string name)
    {
        try
        {
            await SetAuthHeaderAsync();

            var payload = new { name = name };
            var content = new StringContent(JsonSerializer.Serialize(payload), System.Text.Encoding.UTF8, "application/json");
            var response = await _httpClient.PostAsync($"{BaseUrl}/shopping_lists", content);

            if (response.IsSuccessStatusCode)
            {
                var responseContent = await response.Content.ReadAsStringAsync();
                var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
                return JsonSerializer.Deserialize<ShoppingList>(responseContent, options);
            }

            else
            {
                var erroRails = await response.Content.ReadAsStringAsync();
                System.Diagnostics.Debug.WriteLine($"[ERRO AO CRIAR LISTA] {response.StatusCode}: {erroRails}");
            }
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[EXCEÇÃO] {ex.Message}");
        }
        return null;
    }

    public async Task<ListDetailsResponse> GetListDetailsAsync(int listId)
    {
        try
        {
            await SetAuthHeaderAsync();
            var response = await _httpClient.GetAsync($"{BaseUrl}/shopping_lists/{listId}");

            if (response.IsSuccessStatusCode)
            {
                var content = await response.Content.ReadAsStringAsync();
                var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };

                try
                {
                    var fullResponse = JsonSerializer.Deserialize<ListDetailsResponse>(content, options);
                    if (fullResponse?.ListInfo != null && !string.IsNullOrEmpty(fullResponse.ListInfo.Name))
                        return fullResponse;
                }
                catch { }

                var basicList = JsonSerializer.Deserialize<ShoppingList>(content, options);
                if (basicList != null && basicList.Id != 0)
                {
                    return new ListDetailsResponse
                    {
                        ListInfo = basicList,
                        Items = new List<ListItem>(),
                        TopMarkets = new List<MarketPriceSummary>(),
                        BestMarket = null
                    };
                }
            }
        }
        catch { }
        return null;
    }

    public async Task<bool> AddProductToListAsync(int listId, int productId, int quantity = 1)
    {
        try
        {
            await SetAuthHeaderAsync();

            var payload = new { shopping_list_item = new { product_id = productId, quantity = quantity } };
            var content = new StringContent(System.Text.Json.JsonSerializer.Serialize(payload), System.Text.Encoding.UTF8, "application/json");

            var response = await _httpClient.PostAsync($"{BaseUrl}/shopping_lists/{listId}/items", content);
            return response.IsSuccessStatusCode;
        }
        catch
        {
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
}