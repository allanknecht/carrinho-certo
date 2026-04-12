using System.Net.Http.Json;
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
}