using CarrinhoCerto.Pages.Scan;
using ZXing;
using ZXing.Net.Maui;
using ZXing.Net.Maui.Readers;

namespace CarrinhoCerto.Pages.Scan;

public partial class ScanPage : ContentPage
{
    public ScanPage()
    {
        InitializeComponent();

        CameraScanner.Options = new ZXing.Net.Maui.BarcodeReaderOptions
        {
            Formats = ZXing.Net.Maui.BarcodeFormat.QrCode,
            AutoRotate = true,
            Multiple = true
        };
    }

    private void OnBarcodesDetected(object sender, ZXing.Net.Maui.BarcodeDetectionEventArgs e)
    {
        var primeiro = e.Results?.FirstOrDefault();

        if (primeiro is null)
            return;

        //debug
        Dispatcher.DispatchAsync(async () =>
        {
            await DisplayAlert("QR Code Detectado", $"Valor: {primeiro.Value}", "OK");
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
        this.Window.Page = new PosScanPage();
    }
}