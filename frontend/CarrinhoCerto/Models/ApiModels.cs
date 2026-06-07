using System.Collections.Generic;
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

public class ShoppingList
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("name")]
    public string? Name { get; set; }

    [JsonPropertyName("description")]
    public string? Description { get; set; }

    [JsonPropertyName("items_count")]
    public int ItemCount { get; set; }
}

public class ShoppingListsWrapper
{
    [JsonPropertyName("shopping_lists")]
    public List<ShoppingList>? ShoppingLists { get; set; }
}

public class ListItem
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("product_name")]
    public string? ProductName { get; set; }

    [JsonPropertyName("quantity")]
    public int Quantity { get; set; }
}

public class MarketPriceSummary
{
    [JsonPropertyName("market_name")]
    public string? MarketName { get; set; }

    [JsonPropertyName("total_price")]
    public decimal TotalPrice { get; set; }
}

public class ListDetailsResponse
{
    [JsonPropertyName("list_info")]
    public ShoppingList? ListInfo { get; set; }

    [JsonPropertyName("items")]
    public List<ListItem>? Items { get; set; }

    [JsonPropertyName("best_market")]
    public MarketPriceSummary? BestMarket { get; set; }

    [JsonPropertyName("top_markets")]
    public List<MarketPriceSummary>? TopMarkets { get; set; }
}