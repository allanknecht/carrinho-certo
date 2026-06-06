using CarrinhoCerto.Services;

namespace CarrinhoCerto.Pages.Scan;

public partial class QrNumbersPage : ContentPage
{
    private readonly ApiService _apiService;

    public QrNumbersPage()
    {
        InitializeComponent();
        _apiService = new ApiService();
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
        }
        else
        {
            await DisplayAlert("Ops!", result.Message, "OK");
        }
    }
}