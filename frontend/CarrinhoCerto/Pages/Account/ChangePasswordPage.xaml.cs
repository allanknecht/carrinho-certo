using CarrinhoCerto.Pages.Account;

namespace CarrinhoCerto.Pages;

    

public partial class ChangePasswordPage : ContentPage
{
	public ChangePasswordPage()
	{
        InitializeComponent();
	}

    private void OnSalvarClicked(object sender, EventArgs e)
    {
        this.Window.Page = new SuccessPage();
    }

    private void OnVoltarTapped(object sender, TappedEventArgs e)
    {
        var mainTab = new TabNav();
        mainTab.CurrentPage = mainTab.Children[3];

        if (Application.Current != null)
        {
            Application.Current.MainPage = mainTab;
        }
    }
}