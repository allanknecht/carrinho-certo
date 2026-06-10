using CarrinhoCerto.Services;
using Microsoft.Maui.Controls;

namespace CarrinhoCerto.Pages;

public partial class LoginPage : ContentPage
{
    private readonly ApiService _apiService;

    public LoginPage()
    {
        InitializeComponent();

        _apiService = ApiService.Shared;
    }

    private async void Entrar_Clicked(object sender, EventArgs e)
    {
        var btnEntrar = sender as Button;

        string email = EmailEntry.Text;
        string password = PasswordEntry.Text;

        if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(password))
        {
            await DisplayAlert("Aviso", "Por favor, preencha o e-mail e a senha.", "OK");
            return;
        }

        if (btnEntrar != null)
        {
            btnEntrar.IsEnabled = false;
            btnEntrar.Text = "CARREGANDO...";
        }

        var result = await _apiService.LoginAsync(email, password);

        if (result.IsSuccess)
        {
            this.Window.Page = new TabNav();
        }
        else
        {
            await DisplayAlert("Falha no Login", result.ErrorMessage, "OK");

            if (btnEntrar != null)
            {
                btnEntrar.IsEnabled = true;
                btnEntrar.Text = "ENTRAR";
            }
        }
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