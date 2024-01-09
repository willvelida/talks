using Dapr.Client;
using EnqueueMessage.Api.Models;

var builder = WebApplication.CreateBuilder(args);

var app = builder.Build();

app.MapPost("/", async (Customer customer) =>
{
    if (customer.Id is null || customer.CustomerName is null)
    {
        return Results.BadRequest();
    }

    var requestId = Guid.NewGuid().ToString();
    var requestUrl = $"http://{Environment.GetEnvironmentVariable("PROCESSOR_APP_NAME")}/api/RequestStatus/{requestId}";

    Dictionary<string, string> metaData = new Dictionary<string, string>()
    {
        {
            "RequestGUID", requestId
        },
        {
            "RequestSubmittedAt", DateTime.Now.ToString()
        },
        {
            "RequestStatusUrl", requestUrl
        }
    };

    using var client = new DaprClientBuilder().Build();
    await client.PublishEventAsync("queuepubsub", "outqueue", customer, metadata: metaData);

    return Results.Ok();
});

app.Run();

