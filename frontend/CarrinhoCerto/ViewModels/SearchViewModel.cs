using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Windows.Input;
using CarrinhoCerto.Models;
using CarrinhoCerto.Services;
using Microsoft.Maui.Controls;

namespace CarrinhoCerto.ViewModels;

public class SearchViewModel : INotifyPropertyChanged
{
    private readonly ApiService _apiService;

    public ObservableCollection<ProductItemViewModel> Products { get; } = new();

    private string _searchQuery;
    public string SearchQuery
    {
        get => _searchQuery;
        set { _searchQuery = value; OnPropertyChanged(nameof(SearchQuery)); }
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

        _ = SearchProductsAsync();
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
        await Application.Current.Windows[0].Page.Navigation.PushAsync(new Pages.ProductPage(productId));
    }

    public event PropertyChangedEventHandler PropertyChanged;
    protected void OnPropertyChanged(string propertyName) =>
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
}