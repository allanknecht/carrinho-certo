using CarrinhoCerto.Pages.Scan;
using CarrinhoCerto.Pages.Account;
using ZXing;
using ZXing.Net.Maui;
using ZXing.Net.Maui.Readers;
using CarrinhoCerto.Services;

namespace CarrinhoCerto.Pages.Scan;

public partial class ScanPage : ContentPage
{
    private readonly ApiService _apiService;
    private bool _isProcessingScan = false;

    public ScanPage()
    {
        InitializeComponent();

        _apiService = new ApiService();

        CameraScanner.Options = new ZXing.Net.Maui.BarcodeReaderOptions
        {
            Formats = ZXing.Net.Maui.BarcodeFormat.QrCode,
            AutoRotate = true,
            Multiple = false
        };
    }

    private void OnBarcodesDetected(object sender, ZXing.Net.Maui.BarcodeDetectionEventArgs e)
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
                    await janelaPrincipal.DisplayAlert("Sucesso", "Nota enviada para a fila!", "OK");

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

    private void OnBackTapped(object sender, EventArgs e)
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