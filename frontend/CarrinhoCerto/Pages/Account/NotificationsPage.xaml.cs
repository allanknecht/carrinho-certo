using CarrinhoCerto.Pages.Account;
using CarrinhoCerto.Pages;

namespace CarrinhoCerto.Pages.Account;

public partial class NotificationsPage : ContentPage
{
	public NotificationsPage()
	{
		InitializeComponent();
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

    private void OnSalvarClicked(object sender, EventArgs e)
    {
        this.Window.Page = new SuccessPage();
    }
}