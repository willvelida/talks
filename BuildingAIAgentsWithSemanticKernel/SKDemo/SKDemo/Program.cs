using Microsoft.Extensions.Configuration;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;
using Microsoft.SemanticKernel.Plugins.Core;

#pragma warning disable SKEXP0050
var config = new ConfigurationBuilder()
    .AddJsonFile("appsettings.json")
    .Build();

var builder = Kernel.CreateBuilder();
builder.AddAzureOpenAIChatCompletion(
    config["DEPLOYMENT_NAME"],
    config["AZURE_OPEN_AI_ENDPOINT"],
    config["AZURE_OPEN_AI_API_KEY"],
    config["DEPLOYMENT_MODEL"]);
builder.Plugins.AddFromType<ConversationSummaryPlugin>();
var kernel = builder.Build();

var result = await kernel.InvokePromptAsync(
    "Give me a list of breakfast food with eggs and cheese");

Console.WriteLine(result);

string input = @"I'm a vegan in search of new recipes. I love spicy food!
Can you give me a list of breakfast recipes that are vegan friendly?";

var veganResult = await kernel.InvokeAsync(
    "ConversationSummaryPlugin",
    "GetConversationActionItems",
    new() { { "input", input } });

Console.WriteLine(veganResult);

string langauge = "Italian";
string history = @"I'm traveling with my girlfriend who is Italian. I am also lactose intolerant.";
string prompt = $@"
        You are a travel assistant. You are helpful, creative, and very friendly.
    
        Consider the traveler's background: ${history}        

        Create a list of helpful phrases and words in ${langauge} that a traveler would find useful.

        Group phrases by category. Display the phrases in the following format: Hello - Ciao [chow]";

var touristResult = await kernel.InvokePromptAsync(prompt);
Console.WriteLine(touristResult);

string budgetInput = @"I'm planning a trip to Italy and I'm on a tight budget. We like food, muesums, and beaches. Our budget is $5000";
string instruction = $@"
        The following is a conversation with an AI travel assistance bot. The bot is helpful, creative, and very friendly.

        <message role=""user"">Can you give me some travel destination suggestions?</message>
        <message role=""assistant"">Sure! What type of destination are you looking for?</message>
        <message role=""user"">${budgetInput}</message>
";

var budgetResult = await kernel.InvokePromptAsync(instruction);
Console.WriteLine(budgetResult);

var prompts = kernel.ImportPluginFromPromptDirectory("Prompts/TravelPlugins");

ChatHistory chatHistory = [];
var directoryResult = await kernel.InvokeAsync<string>(prompts["SuggestDestinations"],
    new() { { "input", budgetInput } });

Console.WriteLine(directoryResult);
chatHistory.AddUserMessage(budgetInput);
chatHistory.AddAssistantMessage(directoryResult);

Console.WriteLine("Where would you like to go?");
input = Console.ReadLine();

result = await kernel.InvokeAsync(prompts["SuggestActivities"],
    new() {
        { "history", history },
        { "destination", input },
    }
);
Console.WriteLine(result);

