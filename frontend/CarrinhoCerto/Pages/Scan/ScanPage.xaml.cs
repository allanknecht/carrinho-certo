namespace CarrinhoCerto.Pages;

public partial class ScanPage : ContentPage
{
	public ScanPage()
	{
		InitializeComponent();
	}

    private void OnBackTapped(object sender, EventArgs e)
    {
        this.Window.Page = new TabNav();
    }

    private void OnDigitarNumerosTapped(object sender, TappedEventArgs e)
    {
        // this.Window.Page = new xxxxPage();
    }
}