using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Linq;
using System.Threading.Tasks;
using CarrinhoCerto.Models;
using CarrinhoCerto.Services;
using LiveChartsCore;
using LiveChartsCore.SkiaSharpView;
using LiveChartsCore.SkiaSharpView.Painting;
using SkiaSharp;

namespace CarrinhoCerto.ViewModels;

public class ProductViewModel : INotifyPropertyChanged
{
    private readonly ApiService _apiService;

    public Product CurrentProduct { get; set; }
    public StorePrice BestPriceStore { get; set; }
    public ObservableCollection<StorePrice> OtherStores { get; set; } = new();

    public ISeries[] PriceSeries { get; set; }
    public Axis[] XAxes { get; set; } = new Axis[] { new Axis { IsVisible = false } };
    public Axis[] YAxes { get; set; } = new Axis[] { new Axis { IsVisible = false } };

    private bool _isLoading;
    public bool IsLoading
    {
        get => _isLoading;
        set
        {
            _isLoading = value;
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(IsLoading)));
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(IsLoaded)));
        }
    }
    public bool IsLoaded => !IsLoading;

    public SolidColorPaint ChartBackground { get; set; } = new SolidColorPaint(SKColors.Transparent);

    public ProductViewModel(int productId, ApiService? apiService = null)
    {
        _apiService = apiService ?? ApiService.Shared;
        LoadDataAsync(productId);
    }

    private async Task LoadDataAsync(int productId)
    {
        IsLoading = true;

        var response = await _apiService.GetProductPricesAsync(productId);

        if (response != null && response.Product != null)
        {
            CurrentProduct = response.Product;

            if (response.Stores != null && response.Stores.Any())
            {
                var orderedStores = response.Stores.OrderBy(s =>
                    decimal.TryParse(s.UnitPrice, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out decimal price) ? price : 0
                ).ToList();

                BestPriceStore = orderedStores.First();

                OtherStores.Clear();
                foreach (var store in orderedStores.Skip(1))
                {
                    OtherStores.Add(store);
                }

                var chartPrices = orderedStores.Select(s =>
                    decimal.TryParse(s.UnitPrice, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out decimal p) ? (double)p : 0
                ).Reverse().ToList();

                PriceSeries = new ISeries[]
                {
                    new LineSeries<double>
                    {
                        Values = chartPrices,
                        Fill = new SolidColorPaint(new SKColor(232, 0, 0, 30)),
                        Stroke = new SolidColorPaint(new SKColor(232, 0, 0)) { StrokeThickness = 4 },
                        GeometryFill = new SolidColorPaint(SKColors.White),
                        GeometryStroke = new SolidColorPaint(new SKColor(232, 0, 0)) { StrokeThickness = 3 },
                        GeometrySize = 10,
                        LineSmoothness = 0.5
                    }
                };
            }

            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(CurrentProduct)));
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(BestPriceStore)));
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(PriceSeries)));
        }

        IsLoading = false;
    }

    public event PropertyChangedEventHandler PropertyChanged;
}