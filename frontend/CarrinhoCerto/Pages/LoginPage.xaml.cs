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

    private async void TapCadastro_Tapped(object sender, TappedEventArgs e)
    {
        await DisplayAlert("Cadastro", "O fluxo de cadastro será construído em breve.", "OK");
    }

    private async void TapEsqueceu_Tapped(object sender, TappedEventArgs e)
    {
        await DisplayAlert("Recuperar Senha", "O fluxo de recuperação será construído em breve.", "OK");
    }
}