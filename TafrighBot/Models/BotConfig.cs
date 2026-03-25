namespace TafrighBot.Models;

public class BotConfig
{
    public string TelegramBotToken { get; set; } = "";
    public string GroqApiKey { get; set; } = "";
    public string WebhookUrl { get; set; } = "";
    public int Port { get; set; } = 5060;
    public string DbPath { get; set; } = "data/fatwas_bot.db";
}
