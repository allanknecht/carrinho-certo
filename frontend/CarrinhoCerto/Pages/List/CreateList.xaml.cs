namespace CarrinhoCerto.Pages.List;

public partial class CreateList : ContentPage
{
	public CreateList()
	{
		InitializeComponent();
	}

    private async void OnJogarListTapped(object sender, TappedEventArgs e)
    {
        await AnimarRipple(RippleEnviar, (View)sender, e);

        var mainTab = new TabNav();
        mainTab.CurrentPage = mainTab.Children[2];

        if (Application.Current != null)
        {
            Application.Current.Windows[0].Page = mainTab;
        }
    }

    private void OnVoltarTapped(object sender, TappedEventArgs e)
    {
        var mainTab = new TabNav();
        mainTab.CurrentPage = mainTab.Children[1];

        if (Application.Current != null)
        {
            Application.Current.Windows[0].Page = mainTab;
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