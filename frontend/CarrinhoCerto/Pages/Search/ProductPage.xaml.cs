using CarrinhoCerto.Pages.Account;
using CarrinhoCerto.ViewModels;

namespace CarrinhoCerto.Pages;

public partial class ProductPage : ContentPage
{
	public ProductPage(int productId)
	{
		InitializeComponent();
        BindingContext = new ProductViewModel(productId);
    }

	 private void OnAddToListClicked(object sender, EventArgs e)
	{
		this.Window.Page = new SuccessPage();
    }

    private void OnBackClicked(object sender, EventArgs e)
    {
        var mainTab = new TabNav();
        mainTab.CurrentPage = mainTab.Children[2];

        if (Application.Current != null)
        {
            Application.Current.MainPage = mainTab;
        }
    }
}