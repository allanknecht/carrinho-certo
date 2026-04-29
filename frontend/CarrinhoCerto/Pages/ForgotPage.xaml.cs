namespace CarrinhoCerto.Pages;

public partial class ForgotPage : ContentPage
{
	public ForgotPage()
	{
		InitializeComponent();
	}

    private void OnVoltarTapped(object sender, TappedEventArgs e)
    {
        this.Window.Page = new LoginPage();
    }

    public void OnEnviarSolicitacaoClicked(object sender, EventArgs e)
    {
        LoadingIndicator.IsRunning = true;
        LoadingIndicator.IsVisible = true;
    }
}