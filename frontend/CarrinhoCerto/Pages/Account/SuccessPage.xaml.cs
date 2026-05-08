namespace CarrinhoCerto.Pages.Account;

public partial class SuccessPage : ContentPage
{
	public SuccessPage()
	{
		InitializeComponent();
	}

    private void OnVoltarClicked(object sender, EventArgs e)
    {
        this.Window.Page = new TabNav();
    }
}