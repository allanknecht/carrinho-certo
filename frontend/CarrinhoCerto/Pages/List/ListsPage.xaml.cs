using CarrinhoCerto.Models;
using CarrinhoCerto.Pages.List;
using CarrinhoCerto.Services;
using System.Collections.ObjectModel;
using System.Threading.Tasks;

namespace CarrinhoCerto.Pages;

public partial class ListsPage : ContentPage
{
    private readonly ApiService _apiService;
    public ObservableCollection<ShoppingList> MyLists { get; set; } = new();

    public ListsPage()
    {
        InitializeComponent();
        _apiService = new ApiService();
        BindingContext = this;
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();
        var lists = await _apiService.GetMyListsAsync();

        MyLists.Clear();
        foreach (var list in lists)
        {
            MyLists.Add(list);
        }
    }

    private async void OnCriarListTapped(object sender, TappedEventArgs e)
    {
        await AnimarRipple(RippleEnviar, (View)sender, e);

        string listName = await DisplayPromptAsync("Nova Lista", "Qual o nome da sua listinha?", "CRIAR", "CANCELAR", "Ex: Churrasco Domingão");

        if (!string.IsNullOrWhiteSpace(listName))
        {
            var newList = await _apiService.CreateListAsync(listName);
            if (newList != null)
            {
                if (Application.Current != null)
                {
                    Application.Current.Windows[0].Page = new CreateList(newList.Id);
                }
            }
            else
            {
                await DisplayAlert("Erro", "Não foi possível criar a lista agora.", "OK");
            }
        }
    }

    private void OnListTapped(object sender, TappedEventArgs e)
    {
        // Pega o ID da lista clicada
        var border = sender as Border;
        var recognizer = border?.GestureRecognizers.FirstOrDefault(r => r is TapGestureRecognizer) as TapGestureRecognizer;

        if (recognizer?.CommandParameter is int listId)
        {
            if (Application.Current != null)
            {
                Application.Current.Windows[0].Page = new CreateList(listId);
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