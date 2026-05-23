using System.Text.Json.Serialization;

namespace CarrinhoCerto.Models;

public class LoginResponse
{
    [JsonPropertyName("token")]
    public string? Token { get; set; }
}

public class Product
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("display_name")]
    public string? DisplayName { get; set; }

    [JsonPropertyName("normalized_key")]
    public string? NormalizedKey { get; set; }
}

public class ProductListResponse
{
    [JsonPropertyName("products")]
    public List<Product>? Products { get; set; }
}

public class StorePrice
{
    [JsonPropertyName("store_id")]
    public int StoreId { get; set; }

    [JsonPropertyName("nome")]
    public string? Nome { get; set; }

    [JsonPropertyName("observed_on")]
    public string? ObservedOn { get; set; }

    [JsonPropertyName("unit_price")]
    public string? UnitPrice { get; set; }

    [JsonPropertyName("unidade")]
    public string? Unidade { get; set; }
}

public class ProductPricesResponse
{
    [JsonPropertyName("product")]
    public Product? Product { get; set; }

    [JsonPropertyName("stores")]
    public List<StorePrice>? Stores { get; set; }
}