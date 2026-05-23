using CarrinhoCerto.ViewModels;
using Microsoft.Maui.Controls;

namespace CarrinhoCerto.Pages;

public partial class SearchPage : ContentPage
{
    public SearchPage()
    {
        InitializeComponent();
        NavigationPage.SetHasNavigationBar(this, false);
    }

    protected override void OnAppearing()
    {
        base.OnAppearing();

        if (BindingContext is SearchViewModel vm)
        {
            vm.PerformSearchCommand.Execute(null);
        }
    }
}