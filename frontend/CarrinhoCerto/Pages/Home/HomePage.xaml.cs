using CarrinhoCerto.Models;
using CarrinhoCerto.Pages.Scan;
using CarrinhoCerto.Services;
using System.Collections.ObjectModel;
using System.Threading.Tasks;

namespace CarrinhoCerto.Pages;

public class PriceDropItem
{
    public string ProductName { get; set; } = "";
    public string PriceDescription { get; set; } = "";
}

public partial class HomePage : ContentPage
{
    private readonly ApiService _apiService;
    public ObservableCollection<PriceDropItem> TopDrops { get; set; } = new();

    public HomePage()
    {
        InitializeComponent();
        _apiService = ApiService.Shared;
        BindingContext = this;
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();
        await LoadHomeDataAsync();
    }

    private async Task LoadHomeDataAsync()
    {
        var user = await _apiService.GetCurrentUserAsync();
        if (user != null)
        {
            lbUser.Text = user.DisplayName;
        }

        var highlights = await _apiService.GetPriceHighlightsAsync(3);
        TopDrops.Clear();
        foreach (var item in highlights)
        {
            TopDrops.Add(new PriceDropItem
            {
                ProductName = item.ProductName ?? "",
                PriceDescription = item.PriceDescription ?? ""
            });
        }
    }

    private async void OnEnviarNotaTapped(object sender, TappedEventArgs e)
    {
        await AnimarRipple(RippleEnviar, (View)sender, e);

        if (Application.Current != null)
        {
            Application.Current.Windows[0].Page = new ScanPage();
        }
    }

    private async void OnMinhasListasTapped(object sender, TappedEventArgs e)
    {
        await AnimarCorBotao((Border)sender, Color.FromArgb("#F3F4F6"));

        if (Application.Current?.Windows[0].Page is TabbedPage tabbedPage)
        {
            tabbedPage.CurrentPage = tabbedPage.Children[1];
        }
    }

    private async void OnBuscarPrecosTapped(object sender, TappedEventArgs e)
    {
        await AnimarCorBotao((Border)sender, Color.FromArgb("#F3F4F6"));

        if (Application.Current?.Windows[0].Page is TabbedPage tabbedPage)
        {
            tabbedPage.CurrentPage = tabbedPage.Children[2];
        }
    }

    private async Task AnimarCorBotao(Border border, Color corDeClique)
    {
        if (border == null) return;

        Color corOriginal = border.BackgroundColor;
        border.BackgroundColor = corDeClique;
        await Task.Delay(100);
        border.BackgroundColor = corOriginal;
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
