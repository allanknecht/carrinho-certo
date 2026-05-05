using CarrinhoCerto.Services;

namespace CarrinhoCerto.Pages;

public partial class RegisterPage : ContentPage
{
    private readonly ApiService _apiService;

    public RegisterPage()
    {
        InitializeComponent();
        _apiService = new ApiService();
    }

    private async void OnCadastrarClicked(object sender, EventArgs e)
    {
        string email = EmailEntry.Text;
        string password = PasswordEntry.Text;

        if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(password))
        {
            await DisplayAlert("Erro", "Preencha todos os campos.", "OK");
            return;
        }

        LoadingIndicator.IsRunning = true;
        LoadingIndicator.IsVisible = true;

        var (isSuccess, errorMessage) = await _apiService.RegisterUserAsync(email, password);

        LoadingIndicator.IsRunning = false;
        LoadingIndicator.IsVisible = false;

        if (isSuccess)
        {
            await DisplayAlert("Sucesso", "Cadastro realizado com sucesso!", "OK");
            await Task.Delay(3000);
            this.Window.Page = new LoginPage();
        }
        else
        {
            await DisplayAlert("Falha no Cadastro", errorMessage, "OK");
        }
    }

    private void OnVoltarTapped(object sender, TappedEventArgs e)
    {
        this.Window.Page = new LoginPage();
    }
}