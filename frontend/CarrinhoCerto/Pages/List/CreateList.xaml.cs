using CarrinhoCerto.Models;
using CarrinhoCerto.Services;
using System.ComponentModel;
using System.Threading.Tasks;

namespace CarrinhoCerto.Pages.List;

public partial class CreateList : ContentPage, INotifyPropertyChanged
{
    private readonly ApiService _apiService;
    private int _listId;

    private ListDetailsResponse _listData;
    public ListDetailsResponse ListData
    {
        get => _listData;
        set
        {
            _listData = value;
            OnPropertyChanged(nameof(ListData));
        }
    }

    public CreateList()
    {
        InitializeComponent();
        _apiService = new ApiService();
    }

    public CreateList(int listId)
    {
        InitializeComponent();
        _apiService = new ApiService();
        _listId = listId;
        BindingContext = this;

        LoadListDetails();
    }

    private async void LoadListDetails()
    {
        var data = await _apiService.GetListDetailsAsync(_listId);

        if (data != null && data.ListInfo != null && !string.IsNullOrEmpty(data.ListInfo.Name))
        {
            ListData = data;
        }
        else
        {
            var todasAsListas = await _apiService.GetMyListsAsync();
            var minhaLista = todasAsListas?.FirstOrDefault(l => l.Id == _listId);

            string nomeSeguro = minhaLista?.Name ?? $"Lista #{_listId}";

            ListData = new ListDetailsResponse
            {
                ListInfo = new ShoppingList { Id = _listId, Name = nomeSeguro, ItemCount = 0 },
                Items = new List<ListItem>(),
                TopMarkets = new List<MarketPriceSummary>(),
                BestMarket = new MarketPriceSummary { MarketName = "Adicione produtos para ver", TotalPrice = 0 }
            };
        }
    }

    private async void OnEditListTapped(object sender, TappedEventArgs e)
    {
        if (ListData?.ListInfo == null) return;

        string novoNome = await DisplayPromptAsync("Editar Lista", "Qual o novo nome da sua lista?", "SALVAR", "CANCELAR", null, -1, Keyboard.Text, ListData.ListInfo.Name);

        if (!string.IsNullOrWhiteSpace(novoNome) && novoNome != ListData.ListInfo.Name)
        {
            ListData.ListInfo.Name = novoNome;
            OnPropertyChanged(nameof(ListData));

            // await _apiService.UpdateListNameAsync(_listId, novoNome);
        }
    }

    private async void OnRemoveItemTapped(object sender, TappedEventArgs e)
    {
        var result = await DisplayAlert("Aviso", "Remover este item da lista?", "SIM", "NÃO");
        if (result)
        {
            // await _apiService.RemoveListItemAsync(itemId);
            // LoadListDetails();
        }
    }

    private async void OnJogarListTapped(object sender, TappedEventArgs e)
    {
        await AnimarRipple(RippleEnviar, (View)sender, e);

        var mainTab = new TabNav();
        mainTab.CurrentPage = mainTab.Children[2];

        if (Application.Current?.Windows.Count > 0)
        {
            Application.Current.Windows[0].Page = mainTab;
        }
    }

    private void OnVoltarTapped(object sender, TappedEventArgs e)
    {
        var mainTab = new TabNav();
        mainTab.CurrentPage = mainTab.Children[1];

        if (Application.Current?.Windows.Count > 0)
        {
            Application.Current.Windows[0].Page = mainTab;
        }
    }

    private async void OnDeleteListTapped(object sender, EventArgs e)
    {
        bool confirmou = await DisplayAlert("Excluir Lista", $"Tem certeza que quer apagar a lista '{ListData.ListInfo.Name}'?", "SIM, APAGAR", "CANCELAR");

        if (confirmou)
        {
            bool sucesso = await _apiService.DeleteListAsync(_listId);

            if (sucesso)
            {
                await DisplayAlert("Sucesso", "Lista removida!", "OK");

                var mainTab = new TabNav();
                mainTab.CurrentPage = mainTab.Children[1];
                if (Application.Current?.Windows.Count > 0)
                {
                    Application.Current.Windows[0].Page = mainTab;
                }
            }
            else
            {
                await DisplayAlert("Erro", "Não foi possível apagar a lista. Tente novamente.", "OK");
            }
        }
    }

    private async Task AnimarRipple(Microsoft.Maui.Controls.Shapes.Ellipse ripple, View container, TappedEventArgs e)
    {
        var touchPos = e.GetPosition(container);
        if (touchPos == null) return;

        double tamanhoMaximo = 400;
        ripple.TranslationX = touchPos.Value.X - (tamanhoMaximo / 2);
        ripple.TranslationY = touchPos.Value.Y - (tamanhoMaximo / 2);
        ripple.WidthRequest = tamanhoMaximo;
        ripple.HeightRequest = tamanhoMaximo;
        ripple.Scale = 0;
        ripple.Opacity = 0.5;

        await Task.WhenAll(
            ripple.ScaleTo(1, 350, Easing.CubicOut),
            ripple.FadeTo(0, 350, Easing.Linear)
        );

        ripple.Scale = 0;
    }
}