using CarrinhoCerto.Pages.Account;
using CarrinhoCerto.Services;
using System.Threading.Tasks;

namespace CarrinhoCerto.Pages;

public partial class ChangePasswordPage : ContentPage
{
    private readonly ApiService _apiService;

    public ChangePasswordPage()
    {
        InitializeComponent();
        _apiService = new ApiService();
    }

    private async void OnSalvarClicked(object sender, EventArgs e)
    {
        string oldPassword = PasswordEntryOriginal.Text;
        string newPassword = PasswordEntryNew.Text;
        string confirmPassword = PasswordEntryConfirm.Text;

        if (string.IsNullOrWhiteSpace(oldPassword) ||
            string.IsNullOrWhiteSpace(newPassword) ||
            string.IsNullOrWhiteSpace(confirmPassword))
        {
            await DisplayAlert("Aviso", "Preencha todas as senhas para continuar.", "OK");
            return;
        }

        if (newPassword != confirmPassword)
        {
            await DisplayAlert("Erro", "A nova senha e a confirmação não batem. Dá uma olhada aí!", "OK");
            return;
        }

        if (newPassword.Length < 6)
        {
            await DisplayAlert("Erro", "A senha nova precisa ter pelo menos 6 caracteres.", "OK");
            return;
        }

        if (sender is Button btn)
        {
            btn.IsEnabled = false;
            btn.Text = "SALVANDO...";
        }

        await Task.Delay(1500);
        bool isSuccess = true;

        if (sender is Button restoreBtn)
        {
            restoreBtn.IsEnabled = true;
            restoreBtn.Text = "SALVAR";
        }

        if (isSuccess)
        {
            PasswordEntryOriginal.Text = string.Empty;
            PasswordEntryNew.Text = string.Empty;
            PasswordEntryConfirm.Text = string.Empty;

            this.Window.Page = new SuccessPage();
        }
        else
        {
            await DisplayAlert("Ops!", "A senha das antigas está errada. Tenta de novo.", "OK");
        }
    }

    private void OnVoltarTapped(object sender, TappedEventArgs e)
    {
        var mainTab = new TabNav();
        mainTab.CurrentPage = mainTab.Children[3];

        if (Application.Current != null)
        {
            Application.Current.Windows[0].Page = mainTab;
        }
    }
}