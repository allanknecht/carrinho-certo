using CarrinhoCerto.Services;
using Plugin.LocalNotification;
using Microsoft.Maui.Storage;

namespace CarrinhoCerto.Pages.Scan;

public partial class QrNumbersPage : ContentPage
{
    private readonly ApiService _apiService;

    public QrNumbersPage()
    {
        InitializeComponent();
        _apiService = ApiService.Shared;
    }

    private void OnVoltarTapped(object sender, TappedEventArgs e)
    {
        this.Window.Page = new ScanPage();
    }

    public async void OnEnviarClicked(object sender, EventArgs e)
    {
        var urlParams = UrlEntry.Text;

        if (string.IsNullOrWhiteSpace(urlParams))
        {
            await DisplayAlert("Aviso", "Por favor, cole a URL da nota fiscal.", "OK");
            return;
        }

        var btn = (Button)sender;
        btn.IsEnabled = false;
        var textoOriginal = btn.Text;
        btn.Text = "ENVIANDO...";

        var result = await _apiService.SendReceiptUrlAsync(urlParams);

        btn.IsEnabled = true;
        btn.Text = textoOriginal;

        if (result.IsSuccess)
        {
            this.Window.Page = new PosScanPage();

            if (Preferences.Get("NotificarNotaConfirmada", true))
            {
                if (await LocalNotificationCenter.Current.AreNotificationsEnabled() == false)
                {
                    await LocalNotificationCenter.Current.RequestNotificationPermission();
                }

                var request = new NotificationRequest
                {
                    NotificationId = 100,
                    Title = "NOTA CONFIRMADA!",
                    Subtitle = "Carrinho Certo",
                    Description = "A sua nota fiscal bateu no sistema e os preços já foram atualizados.",
                    BadgeNumber = 1,
                    Schedule = new NotificationRequestSchedule { NotifyTime = DateTime.Now.AddSeconds(2) }
                };
                await LocalNotificationCenter.Current.Show(request);
            }
        }
        else
        {
            await DisplayAlert("Ops!", result.Message, "OK");
        }
    }
}