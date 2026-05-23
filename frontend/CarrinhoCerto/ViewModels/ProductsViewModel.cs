using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Linq;
using System.Threading.Tasks;
using CarrinhoCerto.Models;
using CarrinhoCerto.Services;

namespace CarrinhoCerto.ViewModels;

public class ProductViewModel : INotifyPropertyChanged
{
    private readonly ApiService _apiService;

    // Propriedades ligadas à UI
    public Product CurrentProduct { get; set; }
    public StorePrice BestPriceStore { get; set; }
    public ObservableCollection<StorePrice> OtherStores { get; set; } = new();

    private bool _isLoading;
    public bool IsLoading
    {
        get => _isLoading;
        set
        {
            _isLoading = value;
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(IsLoading)));
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(IsLoaded)));
        }
    }
    public bool IsLoaded => !IsLoading;

    public ProductViewModel(int productId)
    {
        _apiService = new ApiService();
        LoadDataAsync(productId);
    }

    private async Task LoadDataAsync(int productId)
    {
        IsLoading = true;

        var response = await _apiService.GetProductPricesAsync(productId);

        if (response != null && response.Product != null)
        {
            CurrentProduct = response.Product;

            if (response.Stores != null && response.Stores.Any())
            {
                // Ordenar do mais barato para o mais caro
                var orderedStores = response.Stores.OrderBy(s =>
                    decimal.TryParse(s.UnitPrice, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out decimal price) ? price : 0
                ).ToList();

                // O mais barato vai para o destaque
                BestPriceStore = orderedStores.First();

                // Os restantes vão para a lista "Outros Mercados"
                OtherStores.Clear();
                foreach (var store in orderedStores.Skip(1))
                {
                    OtherStores.Add(store);
                }
            }

            // Notificar a UI que as propriedades foram atualizadas
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(CurrentProduct)));
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(BestPriceStore)));
        }

        IsLoading = false;
    }

    public event PropertyChangedEventHandler PropertyChanged;
}