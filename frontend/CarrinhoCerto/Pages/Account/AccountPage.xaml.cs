using System.ComponentModel;
using CarrinhoCerto.Pages.Account;
using CarrinhoCerto.Services;
using Microsoft.Maui.Controls;

namespace CarrinhoCerto.Pages;

public partial class AccountPage : ContentPage, INotifyPropertyChanged
{
    private readonly ApiService _apiService;

    public string UserDisplayName { get; set; } = "Carregando...";
    public string UserEmail { get; set; } = "";

    public AccountPage()
    {
        InitializeComponent();
        _apiService = ApiService.Shared;
        BindingContext = this;
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();
        await LoadUserAsync();
    }

    private async Task LoadUserAsync()
    {
        var user = await _apiService.GetCurrentUserAsync();
        if (user != null)
        {
            UserDisplayName = user.DisplayName;
            UserEmail = user.Email ?? "";
            OnPropertyChanged(nameof(UserDisplayName));
            OnPropertyChanged(nameof(UserEmail));
        }
    }

    private void OnAlterarSenhaTapped(object sender, TappedEventArgs e)
    {
        this.Window.Page = new ChangePasswordPage();
    }

    private void OnNotificacoesTapped(object sender, TappedEventArgs e)
    {
        this.Window.Page = new NotificationsPage();
    }

    private async void OnSairContaTapped(object sender, TappedEventArgs e)
    {
        await AnimarRipple(RippleEnviar, (View)sender, e);

        _apiService.Logout();

        MainThread.BeginInvokeOnMainThread(() =>
        {
            if (Application.Current?.Windows.Count > 0)
            {
                Application.Current.Windows[0].Page = new LoginPage();
            }
        });
    }

    private async Task AnimarRipple(Microsoft.Maui.Controls.Shapes.Ellipse ripple, View container, TappedEventArgs e)
    {
        var touchPos = e.GetPosition(container);
        if (touchPos == null) return;

        double tamanhoMaximo = 400;

        ripple.TranslationX = touchPos.Value.X - (tamanhoMaximo / 2);
        ripple.TranslationY = touchPos.Value.Y - (tamanhoMaximo / 2);

        ripple.WidthRequest = tamanhoMaximo;
        ripple.HeightRequest = tamanhoMaximo;
        ripple.Scale = 0;
        ripple.Opacity = 0.5;

        await Task.WhenAll(
            ripple.ScaleTo(1, 350, Easing.CubicOut),
            ripple.FadeTo(0, 350, Easing.Linear)
        );

        ripple.Scale = 0;
    }

    public new event PropertyChangedEventHandler? PropertyChanged;

    private void OnPropertyChanged(string propertyName) =>
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
}
