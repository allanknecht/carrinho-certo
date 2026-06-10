using CarrinhoCerto.Services;
using System.Threading.Tasks;

namespace CarrinhoCerto.Pages;

public partial class ForgotPage : ContentPage
{
    private readonly ApiService _apiService;

    public ForgotPage()
    {
        InitializeComponent();
        _apiService = ApiService.Shared;
    }

    private void OnVoltarTapped(object sender, TappedEventArgs e)
    {
        this.Window.Page = new LoginPage();
    }

    public async void OnEnviarSolicitacaoClicked(object sender, EventArgs e)
    {
        string email = EmailEntry.Text?.Trim();

        if (string.IsNullOrWhiteSpace(email) || !email.Contains("@") || !email.Contains("."))
        {
            await DisplayAlert("Aviso", "Por favor, digite um endereço de e-mail válido.", "OK");
            return;
        }

        var btn = sender as Button;
        if (btn != null)
        {
            btn.IsEnabled = false;
            btn.Text = "ENVIANDO...";
        }

        LoadingIndicator.IsVisible = true;
        LoadingIndicator.IsRunning = true;

        await Task.Delay(1500);

        LoadingIndicator.IsRunning = false;
        LoadingIndicator.IsVisible = false;

        if (btn != null)
        {
            btn.IsEnabled = true;
            btn.Text = "ENVIAR SOLICITAÇÃO";
        }

        await DisplayAlert("Deu boa!", "Se este e-mail estiver registado connosco, vais receber um link com as instruções para criar uma senha nova em poucos minutos.", "FECHAR");

        EmailEntry.Text = string.Empty;
        this.Window.Page = new LoginPage();
    }
}