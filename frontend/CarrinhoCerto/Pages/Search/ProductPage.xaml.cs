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
        var vm = BindingContext as ProductViewModel;
        if (vm?.CurrentProduct == null) return;

        await SecureStorage.Default.SetAsync($"prod_name_{vm.CurrentProduct.Id}", vm.CurrentProduct.DisplayName);

        var listas = await new ApiService().GetMyListsAsync();

        if (listas == null || !listas.Any())
        {
            await DisplayAlert("Aviso", "Você não tem nenhuma lista! Crie uma primeiro na aba de Listas.", "OK");
            return;
        }

        var nomesDasListas = listas.Select(l => !string.IsNullOrEmpty(l.Name) ? l.Name : $"Lista #{l.Id}").ToArray();
        var listaEscolhida = await DisplayActionSheet("Adicionar a qual lista?", "Cancelar", null, nomesDasListas);

        if (listaEscolhida != "Cancelar" && !string.IsNullOrEmpty(listaEscolhida))
        {
            var listaAlvo = listas.FirstOrDefault(l => l.Name == listaEscolhida || $"Lista #{l.Id}" == listaEscolhida);

            if (listaAlvo != null)
            {
                bool sucesso = await new ApiService().AddProductToListAsync(listaAlvo.Id, vm.CurrentProduct.Id);

                if (sucesso)
                {
                    await DisplayAlert("Boa!", "Produto jogado na lista com sucesso!", "OK");
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