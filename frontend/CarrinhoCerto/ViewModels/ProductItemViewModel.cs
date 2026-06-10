using System.ComponentModel;
using System.Linq;
using System.Threading.Tasks;
using CarrinhoCerto.Models;
using CarrinhoCerto.Services;

namespace CarrinhoCerto.ViewModels;

public class ProductItemViewModel : INotifyPropertyChanged
{
    private readonly ApiService _apiService;
    public Product Product { get; }

    public string Emoji => "📦";

    private StorePrice _bestPrice;
    public StorePrice BestPrice
    {
        get => _bestPrice;
        set { _bestPrice = value; OnPropertyChanged(nameof(BestPrice)); OnPropertyChanged(nameof(HasPrices)); }
    }

    private StorePrice _referencePrice;
    public StorePrice ReferencePrice
    {
        get => _referencePrice;
        set { _referencePrice = value; OnPropertyChanged(nameof(ReferencePrice)); OnPropertyChanged(nameof(HasReferencePrice)); }
    }

    public bool HasPrices => BestPrice != null;
    public bool HasReferencePrice => ReferencePrice != null;

    public ProductItemViewModel(Product product, ApiService apiService, bool loadPrices = false)
    {
        Product = product;
        _apiService = apiService;

        if (loadPrices)
        {
            _ = LoadPricesAsync();
        }
    }

    private async Task LoadPricesAsync()
    {
        var response = await _apiService.GetProductPricesAsync(Product.Id);

        if (response != null && response.Stores != null && response.Stores.Any())
        {
            var orderedStores = response.Stores.OrderBy(s =>
                decimal.TryParse(s.UnitPrice, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out decimal p) ? p : 0
            ).ToList();

            BestPrice = orderedStores.First();

            if (orderedStores.Count > 1)
            {
                ReferencePrice = orderedStores[1];
            }
        }
    }

    public event PropertyChangedEventHandler PropertyChanged;
    protected void OnPropertyChanged(string propertyName) =>
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
}