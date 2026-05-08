namespace CarrinhoCerto.Pages.Scan;

public partial class QrNumbersPage : ContentPage
{
	public QrNumbersPage()
	{
		InitializeComponent();
	}

    private void OnVoltarTapped(object sender, TappedEventArgs e)
    {
        this.Window.Page = new ScanPage();
    }

    public void OnEnviarClicked(object sender, EventArgs e)
    {
        this.Window.Page = new PosScanPage();
    }
}