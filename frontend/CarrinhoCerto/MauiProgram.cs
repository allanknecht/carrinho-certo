using Microsoft.Extensions.Logging;
using ZXing.Net.Maui.Controls;
using SkiaSharp.Views.Maui.Controls.Hosting;
using LiveChartsCore.SkiaSharpView.Maui;
using Plugin.LocalNotification;

namespace CarrinhoCerto;

public static class MauiProgram
{
	public static MauiApp CreateMauiApp()
	{
		var builder = MauiApp.CreateBuilder();
		builder
			.UseMauiApp<App>()
            .UseLocalNotification()
            .UseBarcodeReader()
            .UseSkiaSharp()
            .UseLiveCharts()
            .ConfigureFonts(fonts =>
			{
				fonts.AddFont("OpenSans-Regular.ttf", "OpenSansRegular");
				fonts.AddFont("OpenSans-Semibold.ttf", "OpenSansSemibold");
				fonts.AddFont("Poppins-Regular.ttf", "PoppinsRegular");
				fonts.AddFont("Poppins-SemiBold.ttf", "PoppinsSemiBold");
				fonts.AddFont("Poppins-Bold.ttf", "PoppinsBold");
				fonts.AddFont("Poppins-Black.ttf", "PoppinsBlack");
            });

#if DEBUG
		builder.Logging.AddDebug();
#endif

		return builder.Build();
	}
}