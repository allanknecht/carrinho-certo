using CarrinhoCerto.Pages.Scan;
using System.Collections.ObjectModel;
using System.Threading.Tasks;

namespace CarrinhoCerto.Pages;

public class PriceDropItem
{
    public string ProductName { get; set; }
    public string PriceDescription { get; set; }
}

public partial class HomePage : ContentPage
{
    public ObservableCollection<PriceDropItem> TopDrops { get; set; } = new();

    public HomePage()
    {
        InitializeComponent();
        BindingContext = this;
        LoadTopDrops();
    }

    private void LoadTopDrops()
    {
        TopDrops.Add(new PriceDropItem
        {
            ProductName = "Óleo de Soja (900ml)",
            PriceDescription = "R$ 5,49 no Atacadão"
        });

        TopDrops.Add(new PriceDropItem
        {
            ProductName = "Leite Integral Tirol (1L)",
            PriceDescription = "R$ 3,99 no Zaffari"
        });

        TopDrops.Add(new PriceDropItem
        {
            ProductName = "Café Melitta (500g)",
            PriceDescription = "R$ 14,90 no Maxxi"
        });
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