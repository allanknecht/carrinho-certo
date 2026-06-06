using System.Net.Http.Json;
using System.Net.Http.Headers;
using CarrinhoCerto.Models;

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
            var request = new RegisterRequest { email = email, password = password };
            var response = await _httpClient.PostAsJsonAsync($"{BaseUrl}/users", request);

            if (response.IsSuccessStatusCode)
            {
                return (true, string.Empty);
            }
            else
            {
                var errorContent = await response.Content.ReadFromJsonAsync<RegisterErrorResponse>();
                var errorMsg = errorContent?.errors != null
                    ? string.Join("\n", errorContent.errors)
                    : "Erro desconhecido ao criar cadastro.";

                return (false, errorMsg);
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
}