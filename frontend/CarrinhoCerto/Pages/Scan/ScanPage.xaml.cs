using CarrinhoCerto.Pages.Account;
using CarrinhoCerto.Services;
using Microsoft.Maui.Storage;
using Plugin.LocalNotification;
using System;
using System.Linq;
using ZXing.Net.Maui;

namespace CarrinhoCerto.Pages.Scan;

public partial class ScanPage : ContentPage
{
    private readonly ApiService _apiService;
    private bool _isProcessingScan = false;

    public ScanPage()
    {
        InitializeComponent();

        _apiService = new ApiService();

        CameraScanner.Options = new BarcodeReaderOptions
        {
            Formats = BarcodeFormat.QrCode,
            AutoRotate = true,
            Multiple = false
        };
    }

    private void OnBarcodesDetected(object sender, BarcodeDetectionEventArgs e)
    {
        if (_isProcessingScan) return;

        var primeiro = e.Results?.FirstOrDefault();

        if (primeiro is null || string.IsNullOrEmpty(primeiro.Value))
            return;

        _isProcessingScan = true;

        MainThread.BeginInvokeOnMainThread(async () =>
        {
            try
            {
                CameraScanner.IsDetecting = false;
                string urlDaNota = primeiro.Value;

                var result = await _apiService.SendReceiptUrlAsync(urlDaNota);

                var janelaPrincipal = Application.Current.Windows[0].Page;

                if (result.IsSuccess)
                {
                    if (Preferences.Get("NotificarNotaConfirmada", true))
                    {
                        if (await LocalNotificationCenter.Current.AreNotificationsEnabled() == false)
                        {
                            await LocalNotificationCenter.Current.RequestNotificationPermission();
                        }

                        var request = new NotificationRequest
                        {
                            NotificationId = 101,
                            Title = "NOTA ESCANEADA!",
                            Subtitle = "Carrinho Certo",
                            Description = "A sua nota fiscal bateu no sistema e os preços já foram atualizados.",
                            BadgeNumber = 1,
                            Schedule = new NotificationRequestSchedule { NotifyTime = DateTime.Now.AddSeconds(2) }
                        };
                        
                        await LocalNotificationCenter.Current.Show(request);
                    }

                    Application.Current.Windows[0].Page = new PosScanPage();
                }
                else
                {
                    await janelaPrincipal.DisplayAlert("Aviso", result.Message, "OK");
                    _isProcessingScan = false;
                    CameraScanner.IsDetecting = true;
                }
            }
            catch (Exception ex)
            {
                await Application.Current.Windows[0].Page.DisplayAlert("Erro de Ligação", ex.Message, "OK");
                _isProcessingScan = false;
                CameraScanner.IsDetecting = true;
            }
        });
    }

    private void OnBackTapped(object sender, TappedEventArgs e)
    {
        this.Window.Page = new TabNav();
    }

    private void OnDigitarNumerosTapped(object sender, TappedEventArgs e)
    {
        this.Window.Page = new QrNumbersPage();
    }

    private void OnScanenrClicked(object sender, EventArgs e)
    {
        this.Window.Page = new QrNumbersPage();
    }
}