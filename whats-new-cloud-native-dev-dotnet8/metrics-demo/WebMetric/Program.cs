using Bogus;
using OpenTelemetry.Metrics;
using WebMetric;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddOpenTelemetry()
    .WithMetrics(builder =>
    {
        builder.AddPrometheusExporter();

        builder.AddMeter("Microsoft.AspNetCore.Hosting",
                         "Microsoft.AspNetCore.Server.Kestrel");
        builder.AddView("http.server.request.duration",
            new ExplicitBucketHistogramConfiguration
            {
                Boundaries = new double[] { 0, 0.005, 0.01, 0.025, 0.05,
                       0.075, 0.1, 0.25, 0.5, 0.75, 1, 2.5, 5, 7.5, 10 }
            });
    });

// Register the metrics type using DI
builder.Services.AddSingleton<CustomMetrics>();
var app = builder.Build();

app.MapPrometheusScrapingEndpoint();

app.MapGet("/", () => "Hello OpenTelemetry! ticks:"
                     + DateTime.Now.Ticks.ToString()[^3..]);

// We can now inject the custom metrics type and record values where needed.
app.MapGet("/sale", (CustomMetrics metrics) =>
{
    var fakeProduct = new Faker<Product>()
    .RuleFor(p => p.ProductName, (f) => f.Commerce.ProductName())
    .RuleFor(p => p.Quantity, (f) => f.Random.Number(1, 5))
    .Generate();
    metrics.ProductSold(fakeProduct.ProductName, fakeProduct.Quantity);
});

app.Run();