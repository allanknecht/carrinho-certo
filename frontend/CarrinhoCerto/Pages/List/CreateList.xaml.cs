using CarrinhoCerto.Models;
using CarrinhoCerto.Services;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Threading.Tasks;

namespace CarrinhoCerto.Pages.List;

public partial class CreateList : ContentPage
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
            OnPropertyChanged();
        }
    }

    public CreateList(int listId)
    {
        InitializeComponent();
        _apiService = new ApiService();
        _listId = listId;
        BindingContext = this;
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();
        await LoadListDetails();
    }

    private async Task LoadListDetails()
    {
        var data = await _apiService.GetListDetailsAsync(_listId);

        if (data != null && data.ListInfo != null)
        {
            ListData = data;
        }
    }

    private async void OnEditListTapped(object sender, TappedEventArgs e)
    {
        if (ListData?.ListInfo == null) return;

        string novoNome = await DisplayPromptAsync("Editar", "Novo nome da lista:", initialValue: ListData.ListInfo.Name);

        if (!string.IsNullOrWhiteSpace(novoNome) && novoNome != ListData.ListInfo.Name)
        {
            bool sucesso = await _apiService.UpdateListNameAsync(_listId, novoNome);

            if (sucesso)
            {
                await LoadListDetails();
            }
            else
            {
                await DisplayAlert("Erro", "Não foi possível alterar o nome da lista. O servidor rejeitou.", "OK");
            }
        }
    }

    private async void OnDeleteListTapped(object sender, TappedEventArgs e)
    {
        bool confirmou = await DisplayAlert("Atenção", "Tem certeza que deseja apagar esta lista?", "SIM", "NÃO");

        if (confirmou)
        {
            bool sucesso = await _apiService.DeleteListAsync(_listId);

            if (sucesso)
            {
                OnVoltarTapped(null, null);
            }
            else
            {
                await DisplayAlert("Erro", "Não foi possível apagar a lista.", "OK");
            }
        }
    }

    private async void OnRemoveItemTapped(object sender, TappedEventArgs e)
    {
        if (e.Parameter is int itemId)
        {
            bool confirmou = await DisplayAlert("Remover", "Tirar este produto da lista?", "SIM", "NÃO");

            if (confirmou)
            {
                bool sucesso = await _apiService.RemoveListItemAsync(_listId, itemId);

                if (sucesso)
                {
                    await LoadListDetails();
                }
                else
                {
                    await DisplayAlert("Erro", "Não foi possível remover o produto.", "OK");
                }
            }
        }
    }

    private async void OnJogarListTapped(object sender, TappedEventArgs e)
    {
        await AnimarRipple(RippleEnviar, (View)sender, e);

        Preferences.Set("LastActiveListId", _listId);

        var mainTab = new TabNav();
        mainTab.CurrentPage = mainTab.Children[2];
        Application.Current.Windows[0].Page = mainTab;
    }

    private void OnVoltarTapped(object sender, TappedEventArgs e)
    {
        var mainTab = new TabNav();
        mainTab.CurrentPage = mainTab.Children[1];
        Application.Current.Windows[0].Page = mainTab;
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