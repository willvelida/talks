#pragma warning disable SKEXP0050
using Microsoft.Extensions.Configuration;
using Microsoft.SemanticKernel;
using MusicLibrary.Plugins;

var config = new ConfigurationBuilder()
    .AddJsonFile("appsettings.json")
    .Build();

var builder = Kernel.CreateBuilder();
builder.AddAzureOpenAIChatCompletion(
    config["DEPLOYMENT_NAME"],
    config["AZURE_OPEN_AI_ENDPOINT"],
    config["AZURE_OPEN_AI_API_KEY"],
    config["DEPLOYMENT_MODEL"]);

var kernel = builder.Build();
kernel.ImportPluginFromType<MusicLibraryPlugin>();

var result = await kernel.InvokeAsync(
    "MusicLibraryPlugin",
    "AddToRecentlyPlayed",
    new()
    {
        ["artist"] = "Tiara",
        ["song"] = "Danse",
        ["genre"] = "French pop, electropop, pop"
    }
);

Console.WriteLine(result);

string prompt = @"This is a list of music available to the user:
    {{MusicLibraryPlugin.GetMusicLibrary}} 

    This is a list of music the user has recently played:
    {{MusicLibraryPlugin.GetRecentPlays}}

    Based on their recently played music, suggest a song from
    the list to play next";

result = await kernel.InvokePromptAsync(prompt);
Console.WriteLine(result);

