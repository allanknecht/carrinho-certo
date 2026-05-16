namespace CarrinhoCerto.Pages;

public partial class SearchPage : ContentPage
{
	public SearchPage()
	{
		InitializeComponent();
	}

	private void OnProductTapped(object sender, TappedEventArgs e)
	{
		this.Window.Page = new ProductPage();
    }
}