using CarrinhoCerto.Models;
using CarrinhoCerto.Pages.List;
using CarrinhoCerto.ViewModels;
using CarrinhoCerto.Services;
using System.Linq;

namespace CarrinhoCerto.Pages;

public partial class ProductPage : ContentPage
{
    private const int MinQuantity = 1;
    private const int MaxQuantity = 99;

    private readonly ApiService _apiService;
    private int _quantity = 1;
    private bool _isAdding;

    public ProductPage(int productId)
    {
        InitializeComponent();
        _apiService = ApiService.Shared;
        BindingContext = new ProductViewModel(productId, _apiService);
        UpdateQuantityLabel();
    }

    private void OnQuantityDecrease(object sender, EventArgs e)
    {
        if (_quantity > MinQuantity)
        {
            _quantity--;
            UpdateQuantityLabel();
        }
    }

    private void OnQuantityIncrease(object sender, EventArgs e)
    {
        if (_quantity < MaxQuantity)
        {
            _quantity++;
            UpdateQuantityLabel();
        }
    }

    private void UpdateQuantityLabel()
    {
        QuantityLabel.Text = _quantity.ToString();
    }

    private async void OnAddToListClicked(object sender, EventArgs e)
    {
        if (_isAdding) return;

        var vm = BindingContext as ProductViewModel;
        if (vm?.CurrentProduct == null) return;

        var listas = await _apiService.GetMyListsAsync();

        if (listas == null || !listas.Any())
        {
            await DisplayAlert("Aviso", "Voc no tem nenhuma lista! Crie uma primeiro na aba de Listas.", "OK");
            return;
        }

        ShoppingList? listaAlvo = await PickListAsync(listas);
        if (listaAlvo == null) return;

        _isAdding = true;
        AddToListButton.IsEnabled = false;

        try
        {
            bool sucesso = await _apiService.AddProductToListAsync(listaAlvo.Id, vm.CurrentProduct.Id, _quantity);

            if (sucesso)
            {
                Preferences.Set("LastActiveListId", listaAlvo.Id);
                await DisplayAlert("Adicionado!", $"{_quantity}x {vm.CurrentProduct.DisplayName} na lista \"{listaAlvo.Name}\".", "Ver lista");
                GoToList(listaAlvo.Id);
            }
            else
            {
                await DisplayAlert("Ops", "No foi possvel adicionar o produto agora.", "OK");
            }
        }
        finally
        {
            _isAdding = false;
            AddToListButton.IsEnabled = true;
        }
    }

    private async Task<ShoppingList?> PickListAsync(List<ShoppingList> listas)
    {
        if (listas.Count == 1)
        {
            return listas[0];
        }

        var lastListId = Preferences.Get("LastActiveListId", 0);
        var lastList = listas.FirstOrDefault(l => l.Id == lastListId);

        var options = listas
            .OrderByDescending(l => lastList != null && l.Id == lastList.Id)
            .Select(l =>
            {
                var name = !string.IsNullOrEmpty(l.Name) ? l.Name : $"Lista #{l.Id}";
                return lastList != null && l.Id == lastList.Id ? $"{name} (ltima usada)" : name;
            })
            .ToArray();

        var escolha = await DisplayActionSheet("Adicionar a qual lista?", "Cancelar", null, options);
        if (escolha == "Cancelar" || string.IsNullOrEmpty(escolha)) return null;

        var nomeLimpo = escolha.Replace(" (ltima usada)", "");
        return listas.FirstOrDefault(l =>
            (!string.IsNullOrEmpty(l.Name) && l.Name == nomeLimpo) ||
            $"Lista #{l.Id}" == nomeLimpo);
    }

    private void GoToList(int listId)
    {
        if (Application.Current?.Windows.Count > 0)
        {
            Application.Current.Windows[0].Page = new CreateList(listId);
        }
    }

    private void OnBackClicked(object sender, EventArgs e)
    {
        GoToSearch();
    }

    private void GoToSearch()
    {
        var mainTab = new TabNav();
        mainTab.CurrentPage = mainTab.Children[2];

        if (Application.Current?.Windows.Count > 0)
        {
            Application.Current.Windows[0].Page = mainTab;
        }
    }
}
