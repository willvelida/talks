using Azure.Storage.Blobs;
using Azure.Storage.Sas;
using BlobChecker.Api.Enums;

var builder = WebApplication.CreateBuilder(args);

builder.Configuration.AddEnvironmentVariables();

var app = builder.Build();

app.MapGet("/RequestStatus/{blobGuid}", async (HttpRequest req, string blobGuid) =>
{
    OnCompleteEnum onComplete = Enum.Parse<OnCompleteEnum>(req.Query["OnComplete"].FirstOrDefault() ?? "Redirect");
    OnPendingEnum OnPending = Enum.Parse<OnPendingEnum>(req.Query["OnPending"].FirstOrDefault() ?? "OK");

    BlobClient blobClient = new BlobClient(
        Environment.GetEnvironmentVariable("blobconnectionstring"),
        Environment.GetEnvironmentVariable("containername"),
        $"{blobGuid}.blobdata");

    if (await blobClient.ExistsAsync())
    {
        switch (onComplete)
        {
            case OnCompleteEnum.Redirect:
                BlobSasBuilder blobSasBuilder = new BlobSasBuilder
                {
                    BlobContainerName = blobClient.BlobContainerName,
                    BlobName = blobClient.Name,
                    Resource = "b",
                    StartsOn = DateTimeOffset.Now,
                    ExpiresOn = DateTimeOffset.UtcNow.AddMinutes(10)
                }; ;
                blobSasBuilder.SetPermissions(BlobAccountSasPermissions.Read);
                Uri sasUri = blobClient.GenerateSasUri(blobSasBuilder);
                return Results.Ok(sasUri.ToString());
            case OnCompleteEnum.Stream:
                return Results.Ok(await blobClient.DownloadContentAsync());
            default:
                throw new InvalidOperationException($"Unexpected value: {onComplete}");
        }
    }
    else
    {
        switch (OnPending)
        {
            case OnPendingEnum.Ok:
                return Results.Ok(new { status = "In progress" });
            case OnPendingEnum.Synchronous:
                int backoff = 250;
                while (!await blobClient.ExistsAsync() && backoff < 64000)
                {
                    backoff = backoff * 2;
                    await Task.Delay(backoff);
                }
                if (await blobClient.ExistsAsync())
                {

                }
                else
                {
                    return Results.NotFound();
                }
                break;
            default:
                throw new InvalidOperationException($"Unexpected value: {OnPending}");
        }
    }
    return Results.Ok();
});

app.Run();
