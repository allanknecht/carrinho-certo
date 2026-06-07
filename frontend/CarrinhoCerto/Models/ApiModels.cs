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

    [JsonPropertyName("quantidade")]
    public string? QuantidadeRaw { get; set; }

    [JsonPropertyName("product_canonical_id")]
    public int? ProductId { get; set; }

    public string DisplayNameFinal => !string.IsNullOrEmpty(ProductName) ? ProductName : $"Produto #{ProductId}";

    [JsonPropertyName("product_name")]
    public string? ProductName { get; set; }

    public string QuantityFinal => !string.IsNullOrEmpty(QuantidadeRaw) ? $"Qtd: {QuantidadeRaw}" : "Qtd: 1";
}

public class MarketPriceSummary
{
    [JsonPropertyName("market_name")]
    public string? MarketName { get; set; }

    [JsonPropertyName("nome")]
    public string? Nome { get; set; }

    public string NomeFinal => !string.IsNullOrEmpty(MarketName) ? MarketName : (Nome ?? "Mercado");

    [JsonPropertyName("total_price")]
    public decimal TotalPrice { get; set; }

    [JsonPropertyName("total")]
    public decimal Total { get; set; }

    public decimal TotalFinal => TotalPrice > 0 ? TotalPrice : Total;
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

    public bool HasBestMarket => BestMarket != null;
    public bool HasNoBestMarket => BestMarket == null;
}

public class RankingLines
{
    [JsonPropertyName("total")]
    public int Total { get; set; }
    [JsonPropertyName("with_product")]
    public int WithProduct { get; set; }
}

public class RankingResponse
{
    [JsonPropertyName("shopping_list_id")]
    public int ListId { get; set; }

    [JsonPropertyName("lines")]
    public RankingLines? Lines { get; set; }

    [JsonPropertyName("stores")]
    public List<MarketPriceSummary>? Stores { get; set; }
}