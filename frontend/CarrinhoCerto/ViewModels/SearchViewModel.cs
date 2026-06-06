using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Input;
using CarrinhoCerto.Models;
using CarrinhoCerto.Services;
using Microsoft.Maui.Controls;

namespace CarrinhoCerto.ViewModels;

public class SearchViewModel : INotifyPropertyChanged
{
    private readonly ApiService _apiService;
    private CancellationTokenSource _searchCancellationToken;

    public ObservableCollection<ProductItemViewModel> Products { get; } = new();

    public ObservableCollection<StoreFilter> StoreFilters { get; } = new();

    private string _searchQuery;
    public string SearchQuery
    {
        get => _searchQuery;
        set
        {
            _searchQuery = value;
            OnPropertyChanged(nameof(SearchQuery));
            LiveSearchAsync();
        }
    }

    private bool _isLoading;
    public bool IsLoading
    {
        get => _isLoading;
        set { _isLoading = value; OnPropertyChanged(nameof(IsLoading)); }
    }

    public ICommand PerformSearchCommand { get; }
    public ICommand GoToProductCommand { get; }

    public SearchViewModel()
    {
        _apiService = new ApiService();
        PerformSearchCommand = new Command(async () => await SearchProductsAsync());
        GoToProductCommand = new Command<int>(async (productId) => await GoToProductAsync(productId));

        StoreFilters.Add(new StoreFilter { Name = "Todos", IsSelected = true });
        StoreFilters.Add(new StoreFilter { Name = "Mercadões", IsSelected = false });
        StoreFilters.Add(new StoreFilter { Name = "Hiper Mercado", IsSelected = false });

        _ = SearchProductsAsync();
    }

    private async void LiveSearchAsync()
    {
        _searchCancellationToken?.Cancel();
        _searchCancellationToken = new CancellationTokenSource();
        var token = _searchCancellationToken.Token;

        try
        {
            await Task.Delay(500, token);

            if (!token.IsCancellationRequested)
            {
                await SearchProductsAsync();
            }
        }
        catch (TaskCanceledException)
        {
        }
    }

    private async Task SearchProductsAsync()
    {
        IsLoading = true;
        Products.Clear();

        var results = await _apiService.GetProductsAsync(SearchQuery);

        foreach (var p in results)
        {
            Products.Add(new ProductItemViewModel(p, _apiService));
        }

        IsLoading = false;
    }

    private async Task GoToProductAsync(int productId)
    {
        if (Application.Current != null)
        {
            Application.Current.MainPage = new Pages.ProductPage(productId);
        }
    }

    public event PropertyChangedEventHandler PropertyChanged;
    protected void OnPropertyChanged(string propertyName) =>
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
}

public class StoreFilter : INotifyPropertyChanged
{
    public string Name { get; set; }
    private bool _isSelected;
    public bool IsSelected
    {
        get => _isSelected;
        set { _isSelected = value; PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(IsSelected))); }
    }
    public event PropertyChangedEventHandler PropertyChanged;
}