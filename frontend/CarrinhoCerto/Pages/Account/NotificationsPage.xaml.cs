using CarrinhoCerto.Pages.Account;
using CarrinhoCerto.Pages;
using Microsoft.Maui.Storage;

namespace CarrinhoCerto.Pages.Account;

public partial class NotificationsPage : ContentPage
{
    public NotificationsPage()
    {
        InitializeComponent();
        NotaConfirmadaCheck.IsChecked = Preferences.Get("NotificarNotaConfirmada", true);
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

    private void OnSalvarClicked(object sender, EventArgs e)
    {
        Preferences.Set("NotificarNotaConfirmada", NotaConfirmadaCheck.IsChecked);
        this.Window.Page = new SuccessPage();
    }
}