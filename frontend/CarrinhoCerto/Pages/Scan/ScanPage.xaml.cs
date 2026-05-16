using CarrinhoCerto.Pages.Scan;
using ZXing.Net.Maui; 

namespace CarrinhoCerto.Pages.Scan;

public partial class ScanPage : ContentPage
{
    public ScanPage()
    {
        InitializeComponent();

        CameraScanner.Options = new BarcodeReaderOptions
        {
            Formats = BarcodeFormats.TwoDimensional,
            AutoRotate = true,
            Multiple = false
        };
    }

    private void OnBarcodesDetected(object sender, BarcodeDetectionEventArgs e)
    {
        var result = e.Results?.FirstOrDefault();
        if (result != null)
        {
            CameraScanner.IsDetecting = false;

            Dispatcher.Dispatch(() =>
            {
                string qrCodeLido = result.Value;
                this.Window.Page = new PosScanPage();
            });
        }
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