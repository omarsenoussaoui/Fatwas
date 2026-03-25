namespace TafrighBot.Models;

public class Transcription
{
    public long Id { get; set; }
    public long TelegramUserId { get; set; }
    public string UserName { get; set; } = "";
    public string FileName { get; set; } = "";
    public int DurationSeconds { get; set; }
    public string Text { get; set; } = "";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
