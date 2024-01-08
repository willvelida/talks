using Dapr;
using Dapr.Client;

var blobBindingName = "storagecomponent";
var bindingOperationName = "create";

var builder = WebApplication.CreateBuilder(args);

var app = builder.Build();

app.UseCloudEvents();
app.MapSubscribeHandler();

app.MapPost("/", [Topic("queuepubsub", "outqueue")] async (BinaryData customer, IDictionary<string, object> applicationProperties) =>
{
    var id = applicationProperties["RequestGUID"] as string;
    using var client = new DaprClientBuilder().Build();

    IReadOnlyDictionary<string, string> metadata = new Dictionary<string, string>
    {
        {
            "blobName", $"{id}.blobdata"
        }
    };

    await client.InvokeBindingAsync(blobBindingName, bindingOperationName, customer, metadata);
});

app.Run();

