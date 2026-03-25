using Telegram.Bot;
using TafrighBot.Data;
using TafrighBot.Services;

var builder = WebApplication.CreateBuilder(args);

// Read config from environment variables
var botToken = Environment.GetEnvironmentVariable("TELEGRAM_BOT_TOKEN")
    ?? throw new InvalidOperationException("TELEGRAM_BOT_TOKEN is required");
var groqApiKey = Environment.GetEnvironmentVariable("GROQ_API_KEY")
    ?? throw new InvalidOperationException("GROQ_API_KEY is required");
var webhookUrl = Environment.GetEnvironmentVariable("WEBHOOK_URL") ?? "";
var dbPath = Environment.GetEnvironmentVariable("DB_PATH") ?? "data/fatwas_bot.db";
var port = int.Parse(Environment.GetEnvironmentVariable("PORT") ?? "5060");

// Configure Kestrel to listen on the specified port
builder.WebHost.UseUrls($"http://0.0.0.0:{port}");

// Register services
builder.Services.AddSingleton<ITelegramBotClient>(new TelegramBotClient(botToken));
builder.Services.AddSingleton(sp => new GroqTranscriber(groqApiKey, sp.GetRequiredService<ILogger<GroqTranscriber>>()));
builder.Services.AddSingleton(sp => new AudioConverter(sp.GetRequiredService<ILogger<AudioConverter>>()));
builder.Services.AddSingleton(new Database(dbPath));
builder.Services.AddSingleton<BotHandler>();

var app = builder.Build();

// Health check endpoint
app.MapGet("/", () => Results.Ok(new
{
    status = "running",
    bot = "@TafrighFatawaBot",
    description = "بوت تفريغ فتاوى الشيخ بن حنيفية زين العابدين"
}));

app.MapGet("/health", () => Results.Ok("ok"));

var bot = app.Services.GetRequiredService<ITelegramBotClient>();
var handler = app.Services.GetRequiredService<BotHandler>();
var logger = app.Services.GetRequiredService<ILogger<Program>>();

if (!string.IsNullOrEmpty(webhookUrl))
{
    // === WEBHOOK MODE ===
    var webhookPath = "/bot/webhook";
    var fullWebhookUrl = webhookUrl.TrimEnd('/') + webhookPath;

    // Webhook endpoint
    app.MapPost(webhookPath, async (HttpContext ctx) =>
    {
        using var reader = new StreamReader(ctx.Request.Body);
        var json = await reader.ReadToEndAsync();
        var update = System.Text.Json.JsonSerializer.Deserialize<Telegram.Bot.Types.Update>(json,
            new System.Text.Json.JsonSerializerOptions { PropertyNameCaseInsensitive = true });

        if (update != null)
        {
            // Process in background so we return 200 immediately
            _ = Task.Run(() => handler.HandleUpdateAsync(update));
        }

        return Results.Ok();
    });

    // Set webhook on startup
    app.Lifetime.ApplicationStarted.Register(() =>
    {
        Task.Run(async () =>
        {
            try
            {
                await bot.DeleteWebhook();
                await bot.SetWebhook(fullWebhookUrl);
                logger.LogInformation("Webhook set to {Url}", fullWebhookUrl);
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Failed to set webhook");
            }
        });
    });

    // Remove webhook on shutdown
    app.Lifetime.ApplicationStopping.Register(() =>
    {
        Task.Run(async () =>
        {
            try { await bot.DeleteWebhook(); } catch { }
        });
    });

    logger.LogInformation("Starting in WEBHOOK mode on port {Port}", port);
    logger.LogInformation("Webhook URL: {Url}", fullWebhookUrl);
}
else
{
    // === POLLING MODE (local development) ===
    logger.LogInformation("Starting in POLLING mode (no WEBHOOK_URL set)");

    var cts = new CancellationTokenSource();
    app.Lifetime.ApplicationStopping.Register(() => cts.Cancel());

    _ = Task.Run(async () =>
    {
        await bot.DeleteWebhook();
        int? offset = null;

        logger.LogInformation("Polling started...");

        while (!cts.Token.IsCancellationRequested)
        {
            try
            {
                var updates = await bot.GetUpdates(offset: offset, timeout: 30,
                    cancellationToken: cts.Token);

                foreach (var update in updates)
                {
                    offset = update.Id + 1;
                    _ = Task.Run(() => handler.HandleUpdateAsync(update));
                }
            }
            catch (OperationCanceledException) { break; }
            catch (Exception ex)
            {
                logger.LogError(ex, "Polling error");
                await Task.Delay(2000);
            }
        }
    });
}

app.Run();
