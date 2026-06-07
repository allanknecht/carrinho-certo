using CarrinhoCerto.Pages.Account;
using CarrinhoCerto.ViewModels;
using CarrinhoCerto.Services;
using System.Linq;

namespace CarrinhoCerto.Pages;

public partial class ProductPage : ContentPage
{
    private readonly ApiService _apiService;

    public ProductPage(int productId)
    {
        InitializeComponent();
        _apiService = new ApiService();
        BindingContext = new ProductViewModel(productId);
    }

    private async void OnAddToListClicked(object sender, EventArgs e)
    {
        var lists = await _apiService.GetMyListsAsync();

        if (lists == null || lists.Count == 0)
        {
            await DisplayAlert("Aviso", "Você não tem nenhuma lista criada. Vá à aba de Listas e crie uma primeiro!", "OK");
            return;
        }

        var listNames = lists.Select(l => l.Name).ToArray();

        var listaEscolhida = await DisplayActionSheet("Adicionar em qual lista?", "Cancelar", null, listNames);

        if (listaEscolhida != "Cancelar" && !string.IsNullOrEmpty(listaEscolhida))
        {
            var selectedList = lists.FirstOrDefault(l => l.Name == listaEscolhida);
            var vm = BindingContext as ProductViewModel;

            if (selectedList != null && vm?.CurrentProduct != null)
            {
                var sucesso = await _apiService.AddProductToListAsync(selectedList.Id, vm.CurrentProduct.Id);

                if (sucesso)
                {
                    await DisplayAlert("Boa!", $"{vm.CurrentProduct.DisplayName} foi atirado para a lista '{selectedList.Name}'!", "OK");
                }
                else
                {
                    await DisplayAlert("Ops", "Não foi possível adicionar o produto agora.", "OK");
                }
            }
        }
    }

    private void OnBackClicked(object sender, EventArgs e)
    {
        var mainTab = new TabNav();
        mainTab.CurrentPage = mainTab.Children[2];

        if (Application.Current?.Windows.Count > 0)
        {
            Application.Current.Windows[0].Page = mainTab;
        }
    }
}