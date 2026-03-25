using Telegram.Bot;
using Telegram.Bot.Types;
using Telegram.Bot.Types.Enums;
using TafrighBot.Data;
using TafrighBot.Models;

namespace TafrighBot.Services;

public class BotHandler
{
    private const string SheikhName = "الشيخ بن حنيفية زين العابدين";
    private const int TelegramMaxLength = 4096;

    private readonly ITelegramBotClient _bot;
    private readonly GroqTranscriber _transcriber;
    private readonly AudioConverter _converter;
    private readonly Database _db;
    private readonly ILogger<BotHandler> _logger;

    public BotHandler(
        ITelegramBotClient bot,
        GroqTranscriber transcriber,
        AudioConverter converter,
        Database db,
        ILogger<BotHandler> logger)
    {
        _bot = bot;
        _transcriber = transcriber;
        _converter = converter;
        _db = db;
        _logger = logger;
    }

    public async Task HandleUpdateAsync(Update update)
    {
        try
        {
            if (update.Message is { } message)
                await HandleMessageAsync(message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error handling update {UpdateId}", update.Id);
        }
    }

    private async Task HandleMessageAsync(Message message)
    {
        // Handle commands
        if (message.Text?.StartsWith('/') == true)
        {
            var command = message.Text.Split(' ')[0].Split('@')[0].ToLower();
            switch (command)
            {
                case "/start":
                    var userId = message.From?.Id ?? message.Chat.Id;
                    var isFirstUse = await _db.IsFirstUseAsync(userId);
                    await SendStartMessage(message.Chat.Id, isFirstUse);
                    return;
                case "/help":
                    await SendHelpMessage(message.Chat.Id);
                    return;
                case "/history":
                    await SendHistory(message);
                    return;
                case "/stats":
                    await SendStats(message);
                    return;
            }
        }

        // Handle voice messages
        if (message.Voice != null)
        {
            await ProcessAudioAsync(message, message.Voice.FileId,
                "voice.ogg", message.Voice.Duration);
            return;
        }

        // Handle audio files
        if (message.Audio != null)
        {
            var fileName = message.Audio.FileName ?? "audio.mp3";
            await ProcessAudioAsync(message, message.Audio.FileId,
                fileName, message.Audio.Duration);
            return;
        }

        // Handle documents that are audio or video
        if (message.Document != null && IsMediaMimeType(message.Document.MimeType))
        {
            var fileName = message.Document.FileName ?? "media.mp4";
            await ProcessAudioAsync(message, message.Document.FileId, fileName, 0);
            return;
        }

        // Handle video messages
        if (message.Video != null)
        {
            var fileName = message.Video.FileName ?? "video.mp4";
            await ProcessAudioAsync(message, message.Video.FileId,
                fileName, message.Video.Duration);
            return;
        }

        // Handle video notes (round videos)
        if (message.VideoNote != null)
        {
            await ProcessAudioAsync(message, message.VideoNote.FileId,
                "video_note.mp4", message.VideoNote.Duration);
            return;
        }

        // Not an audio/video message
        await _bot.SendMessage(
            chatId: message.Chat.Id,
            text: "🎤 أرسل لي رسالة صوتية أو ملف صوتي أو فيديو وسأقوم بتحويله إلى نص.\n\n"
                + "اكتب /help للمساعدة.",
            replyParameters: new ReplyParameters { MessageId = message.MessageId }
        );
    }

    private async Task ProcessAudioAsync(Message message, string fileId, string fileName, int duration)
    {
        var chatId = message.Chat.Id;
        var userId = message.From?.Id ?? chatId;
        var userName = message.From?.FirstName ?? "";

        // Send "typing" action
        await _bot.SendChatAction(chatId, ChatAction.Typing);

        // Send processing message
        var processingMsg = await _bot.SendMessage(
            chatId: chatId,
            text: "⏳ جاري تحويل الصوت إلى نص...\nيرجى الانتظار.",
            replyParameters: new ReplyParameters { MessageId = message.MessageId }
        );

        try
        {
            // Download file from Telegram (local Bot API supports up to 2GB)
            _logger.LogInformation("Getting file info for {FileId}...", fileId);
            var file = await _bot.GetFile(fileId);
            _logger.LogInformation("File path: {Path}, Size: {Size}", file.FilePath, file.FileSize);

            byte[] rawData;

            // Local Bot API returns absolute file paths on disk
            if (file.FilePath != null && (file.FilePath.StartsWith("/") || Path.IsPathRooted(file.FilePath)))
            {
                // Try reading directly from shared volume
                var localPath = file.FilePath;
                if (!File.Exists(localPath))
                {
                    // Try under the telegram-bot-api data directory
                    localPath = Path.Combine("/var/lib/telegram-bot-api", file.FilePath.TrimStart('/'));
                }

                if (File.Exists(localPath))
                {
                    _logger.LogInformation("Reading file directly from disk: {Path}", localPath);
                    rawData = await File.ReadAllBytesAsync(localPath);
                }
                else
                {
                    _logger.LogWarning("Local file not found at {Path}, falling back to API download", localPath);
                    using var ms = new MemoryStream();
                    await _bot.DownloadFile(file.FilePath, ms);
                    rawData = ms.ToArray();
                }
            }
            else
            {
                // Standard download via Bot API
                using var ms = new MemoryStream();
                await _bot.DownloadFile(file.FilePath!, ms);
                rawData = ms.ToArray();
            }

            _logger.LogInformation("Downloaded {FileName} ({Size}KB) for user {UserId}",
                fileName, rawData.Length / 1024, userId);

            // Compress/convert audio with ffmpeg if needed
            var (audioData, processedName) = await _converter.CompressForGroqAsync(rawData, fileName);

            _logger.LogInformation("Transcribing {FileName} ({Size}KB)", processedName, audioData.Length / 1024);

            // Transcribe
            var text = await _transcriber.TranscribeAsync(audioData, processedName);

            // Save to database
            await _db.SaveTranscriptionAsync(new Transcription
            {
                TelegramUserId = userId,
                UserName = userName,
                FileName = fileName,
                DurationSeconds = duration,
                Text = text,
                CreatedAt = DateTime.UtcNow
            });

            // Delete processing message
            try { await _bot.DeleteMessage(chatId, processingMsg.MessageId); } catch { }

            // Send result — handle Telegram's 4096 char limit
            var header = $"📝 *{SheikhName}*\n"
                       + $"📁 `{EscapeMarkdown(fileName)}`\n"
                       + "━━━━━━━━━━━━━━━\n\n";

            var fullMessage = header + EscapeMarkdown(text);

            if (fullMessage.Length <= TelegramMaxLength)
            {
                await _bot.SendMessage(
                    chatId: chatId,
                    text: fullMessage,
                    parseMode: ParseMode.MarkdownV2,
                    replyParameters: new ReplyParameters { MessageId = message.MessageId }
                );
            }
            else
            {
                // Send header first
                await _bot.SendMessage(
                    chatId: chatId,
                    text: header + EscapeMarkdown(text[..(TelegramMaxLength - header.Length - 50)]) + "\n\n⬇️ *يتبع\\.\\.\\.*",
                    parseMode: ParseMode.MarkdownV2,
                    replyParameters: new ReplyParameters { MessageId = message.MessageId }
                );

                // Send remaining parts
                var remaining = text[(TelegramMaxLength - header.Length - 50)..];
                while (remaining.Length > 0)
                {
                    var chunk = remaining.Length > TelegramMaxLength - 10
                        ? remaining[..(TelegramMaxLength - 10)]
                        : remaining;
                    remaining = remaining[chunk.Length..];

                    var suffix = remaining.Length > 0 ? "\n\n⬇️ *يتبع\\.\\.\\.*" : "\n\n✅ *انتهى*";
                    await _bot.SendMessage(
                        chatId: chatId,
                        text: EscapeMarkdown(chunk) + suffix,
                        parseMode: ParseMode.MarkdownV2
                    );
                }
            }

            _logger.LogInformation("Successfully transcribed {FileName} for user {UserId}", fileName, userId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Transcription failed for {FileName}", fileName);

            // Delete processing message
            try { await _bot.DeleteMessage(chatId, processingMsg.MessageId); } catch { }

            // Detect Telegram file too big error
            var errorText = ex.Message.Contains("file is too big", StringComparison.OrdinalIgnoreCase)
                ? "❌ حجم الملف كبير جداً (أكثر من 20MB).\n\n"
                  + "💡 الحلول:\n"
                  + "• قص الفيديو إلى مقاطع أصغر\n"
                  + "• أرسل الصوت فقط بدون فيديو\n"
                  + "• استخدم تطبيق الجوال للملفات الكبيرة"
                : $"❌ فشل التحويل: {GetArabicErrorMessage(ex)}\n\nأعد إرسال الملف للمحاولة مرة أخرى.";

            await _bot.SendMessage(
                chatId: chatId,
                text: errorText,
                replyParameters: new ReplyParameters { MessageId = message.MessageId }
            );
        }
    }

    private async Task SendStartMessage(long chatId, bool isFirstUse)
    {
        var text = "﷽\n\n"
            + $"🕌 *مرحباً بكم في بوت تفريغ فتاوى*\n*{EscapeMarkdown(SheikhName)}*\n\n"
            + "هذا البوت يقوم بتحويل الرسائل الصوتية والمقاطع المرئية إلى نص مكتوب\\.\n\n"
            + "📌 *طريقة الاستخدام:*\n"
            + "1️⃣ أرسل أو أعد توجيه رسالة صوتية أو فيديو\n"
            + "2️⃣ أو أرسل ملف صوتي \\(mp3, wav, m4a, ogg\\) أو فيديو \\(mp4, webm\\)\n"
            + "3️⃣ انتظر قليلاً وستحصل على النص\n\n"
            + "يمكنك إرسال عدة رسائل وسيتم تحويل كل واحدة على حدة\\.\n\n"
            + "اكتب /help لمزيد من المعلومات\\.";

        await _bot.SendMessage(chatId: chatId, text: text, parseMode: ParseMode.MarkdownV2);

        if (isFirstUse)
        {
            var sadaqa = "━━━━━━━━━━━━━━━\n\n"
                + "🤲 *نسألكم الدعاء*\n\n"
                + "نرجو منكم الدعاء للقائمين على هذا البوت ولوالديهم بالمغفرة والرحمة\\.\n"
                + "وندعو كذلك للأخ مهدي على توجيهه ودعمه لنا\\.\n\n"
                + "اللهم اغفر لهم ولوالديهم وارحمهم وعافهم واعف عنهم\n\n"
                + "جزاكم الله خيراً 🤲\n"
                + "━━━━━━━━━━━━━━━";

            await _bot.SendMessage(chatId: chatId, text: sadaqa, parseMode: ParseMode.MarkdownV2);
        }
    }

    private async Task SendHelpMessage(long chatId)
    {
        var text = "📖 *المساعدة*\n\n"
            + "🎤 *إرسال صوت أو فيديو:* أرسل رسالة صوتية أو فيديو أو ملف وسيتم تحويله إلى نص\n\n"
            + "📋 *الأوامر المتاحة:*\n"
            + "/start \\- رسالة الترحيب\n"
            + "/help \\- هذه المساعدة\n"
            + "/history \\- آخر 10 تفريغات\n"
            + "/stats \\- إحصائياتك\n\n"
            + "📁 *الصيغ المدعومة:*\n"
            + "🔊 صوت: mp3, wav, m4a, ogg, flac, webm\n"
            + "🎬 فيديو: mp4, webm, فيديو دائري\n\n"
            + "⚠️ *الحد الأقصى:* 25MB لكل ملف\n\n"
            + $"🕌 *{EscapeMarkdown(SheikhName)}*";

        await _bot.SendMessage(chatId: chatId, text: text, parseMode: ParseMode.MarkdownV2);
    }

    private async Task SendHistory(Message message)
    {
        var userId = message.From?.Id ?? message.Chat.Id;
        var history = await _db.GetHistoryAsync(userId);
        var items = history.ToList();

        if (items.Count == 0)
        {
            await _bot.SendMessage(
                chatId: message.Chat.Id,
                text: "📭 لا توجد تفريغات سابقة.\n\nأرسل رسالة صوتية لبدء التفريغ."
            );
            return;
        }

        var text = "📜 *آخر التفريغات:*\n\n";
        for (int i = 0; i < items.Count; i++)
        {
            var t = items[i];
            var date = t.CreatedAt.ToString("yyyy/MM/dd HH:mm");
            var preview = t.Text.Length > 80 ? t.Text[..80] + "..." : t.Text;
            text += $"{i + 1}\\. 📁 `{EscapeMarkdown(t.FileName)}`\n"
                  + $"   📅 {EscapeMarkdown(date)}\n"
                  + $"   {EscapeMarkdown(preview)}\n\n";
        }

        // Truncate if too long
        if (text.Length > TelegramMaxLength)
            text = text[..(TelegramMaxLength - 10)] + "\n\\.\\.\\.";

        await _bot.SendMessage(
            chatId: message.Chat.Id,
            text: text,
            parseMode: ParseMode.MarkdownV2
        );
    }

    private async Task SendStats(Message message)
    {
        var userId = message.From?.Id ?? message.Chat.Id;
        var (userCount, totalCount) = await _db.GetStatsAsync(userId);

        var text = "📊 *الإحصائيات*\n\n"
            + $"👤 تفريغاتك: *{userCount}*\n"
            + $"🌍 إجمالي التفريغات: *{totalCount}*\n\n"
            + $"🕌 *{EscapeMarkdown(SheikhName)}*";

        await _bot.SendMessage(
            chatId: message.Chat.Id,
            text: text,
            parseMode: ParseMode.MarkdownV2
        );
    }

    private static bool IsMediaMimeType(string? mimeType)
    {
        if (string.IsNullOrEmpty(mimeType)) return false;
        return mimeType.StartsWith("audio/") ||
               mimeType.StartsWith("video/") ||
               mimeType == "application/ogg";
    }

    private static string GetArabicErrorMessage(Exception ex)
    {
        var msg = ex.Message;
        if (msg.Contains("Network", StringComparison.OrdinalIgnoreCase) ||
            msg.Contains("connection", StringComparison.OrdinalIgnoreCase))
            return "خطأ في الاتصال بالشبكة";
        if (msg.Contains("timeout", StringComparison.OrdinalIgnoreCase))
            return "انتهت مهلة الاتصال";
        if (msg.Contains("API key", StringComparison.OrdinalIgnoreCase) ||
            msg.Contains("401", StringComparison.OrdinalIgnoreCase))
            return "مفتاح API غير صالح";
        if (msg.Contains("rate limit", StringComparison.OrdinalIgnoreCase) ||
            msg.Contains("429", StringComparison.OrdinalIgnoreCase))
            return "تم تجاوز الحد المسموح — حاول لاحقاً";
        if (msg.Contains("ffmpeg", StringComparison.OrdinalIgnoreCase))
            return "فشل تحويل الملف — صيغة غير مدعومة";
        // If already Arabic, return as-is
        if (msg.Any(c => c >= 0x0600 && c <= 0x06FF))
            return msg;
        return "خطأ غير متوقع — حاول مرة أخرى";
    }

    private static string EscapeMarkdown(string text)
    {
        // Escape MarkdownV2 special characters
        var chars = new[] { '_', '*', '[', ']', '(', ')', '~', '`', '>', '#', '+', '-', '=', '|', '{', '}', '.', '!' };
        foreach (var c in chars)
            text = text.Replace(c.ToString(), $"\\{c}");
        return text;
    }
}
