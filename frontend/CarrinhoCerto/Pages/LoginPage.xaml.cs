namespace CarrinhoCerto.Pages;

public partial class LoginPage : ContentPage
{
	public LoginPage()
	{
		InitializeComponent();
	}

    private void Entrar_Clicked(object sender, EventArgs e)
    {
        this.Window.Page = new TabNav();
    }

    private void TapCadastro_Tapped(object sender, TappedEventArgs e)
    {
        this.Window.Page = new RegisterPage();
    }

    private void TapEsqueceu_Tapped(object sender, TappedEventArgs e)
    {
        this.Window.Page = new ForgotPage();
    }
}