namespace CarrinhoCerto.Pages;

public partial class TabNav : TabbedPage
{
    public TabNav()
    {
        InitializeComponent();

        var paginaInicio = new HomePage()
        {
            Title = "Início",
            IconImageSource = "house.svg"
        };

        var paginaListas = new ListsPage()
        {
            Title = "Listas",
            IconImageSource = "list.svg"
        };

        var paginaBusca = new SearchPage()
        {
            Title = "Busca",
            IconImageSource = "search.svg"
        };

        var paginaConta = new AccountPage()
        {
            Title = "Conta",
            IconImageSource = "user.svg",
        };

        this.Children.Add(paginaInicio);
        this.Children.Add(paginaListas);
        this.Children.Add(paginaBusca);
        this.Children.Add(paginaConta);
    }
}