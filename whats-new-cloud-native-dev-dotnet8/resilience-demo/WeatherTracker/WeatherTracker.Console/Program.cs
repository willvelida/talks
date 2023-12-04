using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Http.Resilience;
using Polly;
using System.Diagnostics;

HostApplicationBuilder builder = Host.CreateApplicationBuilder(args);
IServiceCollection services = builder.Services;

// Register HTTP client
services.AddHttpClient("weather", client => client.BaseAddress = new Uri("http://localhost:5080"))
	// Add your resilience handlers here!
	.AddResilienceHandler("demo", builder =>
	{
		// 4. Rate limiter
		builder.AddConcurrencyLimiter(100);

		// 2. Retry pattern
		builder.AddRetry(new HttpRetryStrategyOptions
		{
			MaxRetryAttempts = 5,
			BackoffType = DelayBackoffType.Exponential,
			UseJitter = true,
			Delay = TimeSpan.Zero,
		});

		// 3. Circuit Breaker
		builder.AddCircuitBreaker(new HttpCircuitBreakerStrategyOptions
		{
			SamplingDuration = TimeSpan.FromSeconds(5),
			FailureRatio = 0.9,
			MinimumThroughput = 5,
			BreakDuration = TimeSpan.FromSeconds(5)
		});

		// 1 .Timeout
		builder.AddTimeout(TimeSpan.FromSeconds(1));
	});
// Or, if you want these by default, just add:
// // .AddStandardResilienceHandler()
// // .Configure(options => { // use options to customize policies }


// Create HTTP Client
var httpClient = builder.Build().Services
    .GetRequiredService<IHttpClientFactory>()
    .CreateClient("weather");

while(true)
{
	var watch = Stopwatch.StartNew();

	try
	{
		using var response = await httpClient.GetAsync("weatherforecast");

        Console.WriteLine($"{(int)response.StatusCode}: {watch.Elapsed.TotalMilliseconds,10:0.00}ms");
    }
	catch (Exception ex)
	{
        Console.WriteLine($"Err: {watch.Elapsed.TotalMilliseconds,10:0.00}ms ({ex.GetType().Name})");
	}
}