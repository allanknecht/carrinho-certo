using CarrinhoCerto.Pages.Account;

namespace CarrinhoCerto.Pages;


public partial class AccountPage : ContentPage
{
	public AccountPage()
	{
		InitializeComponent();
	}

    private void OnAlterarSenhaTapped(object sender, TappedEventArgs e)
    {
        this.Window.Page = new ChangePasswordPage();
    }

    private void OnNotificacoesTapped(object sender, TappedEventArgs e)
    {
        this.Window.Page = new NotificationsPage();
    }

    private void OnSairContaTapped(object sender, TappedEventArgs e)
    {
        _ = AnimarRipple(RippleEnviar, (View)sender, e);
        this.Window.Page = new LoginPage();
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