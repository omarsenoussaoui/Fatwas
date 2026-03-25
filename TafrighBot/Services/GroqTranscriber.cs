using System.Net.Http.Headers;
using System.Text.Json;

namespace TafrighBot.Services;

public class GroqTranscriber
{
    private const string ApiUrl = "https://api.groq.com/openai/v1/audio/transcriptions";
    private const string Model = "whisper-large-v3";
    private const string Language = "ar";
    private const int MaxRetries = 3;
    private const int RetryDelaySeconds = 3;
    private const long MaxFileSize = 25 * 1024 * 1024; // 25MB

    private readonly HttpClient _http;
    private readonly string _apiKey;
    private readonly ILogger<GroqTranscriber> _logger;

    public GroqTranscriber(string apiKey, ILogger<GroqTranscriber> logger)
    {
        _apiKey = apiKey;
        _logger = logger;
        _http = new HttpClient { Timeout = TimeSpan.FromMinutes(5) };
    }

    public async Task<string> TranscribeAsync(byte[] audioData, string fileName)
    {
        if (audioData.Length > MaxFileSize)
            throw new InvalidOperationException(
                $"حجم الملف كبير جداً ({audioData.Length / 1024 / 1024}MB). الحد الأقصى 25MB.");

        for (int attempt = 0; attempt <= MaxRetries; attempt++)
        {
            try
            {
                return await SendRequestAsync(audioData, fileName);
            }
            catch (HttpRequestException ex) when (attempt < MaxRetries)
            {
                _logger.LogWarning("Transcription attempt {Attempt} failed: {Error}. Retrying...",
                    attempt + 1, ex.Message);
                await Task.Delay(TimeSpan.FromSeconds(RetryDelaySeconds * (attempt + 1)));
            }
            catch (GroqRateLimitException) when (attempt < MaxRetries)
            {
                _logger.LogWarning("Rate limited on attempt {Attempt}. Waiting...", attempt + 1);
                await Task.Delay(TimeSpan.FromSeconds(RetryDelaySeconds * (attempt + 1)));
            }
        }

        throw new InvalidOperationException("فشل التحويل بعد عدة محاولات. حاول لاحقاً.");
    }

    private async Task<string> SendRequestAsync(byte[] audioData, string fileName)
    {
        using var content = new MultipartFormDataContent();
        var fileContent = new ByteArrayContent(audioData);
        fileContent.Headers.ContentType = new MediaTypeHeaderValue(GetMimeType(fileName));
        content.Add(fileContent, "file", fileName);
        content.Add(new StringContent(Model), "model");
        content.Add(new StringContent(Language), "language");
        content.Add(new StringContent("json"), "response_format");

        using var request = new HttpRequestMessage(HttpMethod.Post, ApiUrl) { Content = content };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _apiKey);

        var response = await _http.SendAsync(request);

        if (response.StatusCode == System.Net.HttpStatusCode.TooManyRequests)
            throw new GroqRateLimitException();

        var body = await response.Content.ReadAsStringAsync();

        if (!response.IsSuccessStatusCode)
        {
            _logger.LogError("Groq API error {Status}: {Body}", (int)response.StatusCode, body);
            var errorMsg = TryParseError(body) ?? $"خطأ من الخادم (HTTP {(int)response.StatusCode})";
            throw new HttpRequestException(errorMsg);
        }

        return ParseTranscription(body);
    }

    private static string ParseTranscription(string body)
    {
        try
        {
            using var doc = JsonDocument.Parse(body);
            var text = doc.RootElement.GetProperty("text").GetString();
            if (string.IsNullOrWhiteSpace(text))
                throw new InvalidOperationException("لم يتم العثور على نص في الاستجابة");
            return text;
        }
        catch (JsonException)
        {
            // If response is plain text
            if (!string.IsNullOrWhiteSpace(body))
                return body.Trim();
            throw new InvalidOperationException("استجابة غير صالحة من الخادم");
        }
    }

    private static string? TryParseError(string body)
    {
        try
        {
            using var doc = JsonDocument.Parse(body);
            if (doc.RootElement.TryGetProperty("error", out var error))
            {
                if (error.ValueKind == JsonValueKind.Object &&
                    error.TryGetProperty("message", out var msg))
                    return msg.GetString();
                if (error.ValueKind == JsonValueKind.String)
                    return error.GetString();
            }
        }
        catch { }
        return null;
    }

    private static string GetMimeType(string fileName)
    {
        var ext = Path.GetExtension(fileName).ToLowerInvariant();
        return ext switch
        {
            ".mp3" => "audio/mpeg",
            ".wav" => "audio/wav",
            ".m4a" => "audio/mp4",
            ".ogg" => "audio/ogg",
            ".oga" => "audio/ogg",
            ".flac" => "audio/flac",
            ".webm" => "audio/webm",
            ".mp4" => "video/mp4",
            ".mkv" => "video/x-matroska",
            ".avi" => "video/x-msvideo",
            ".mov" => "video/quicktime",
            _ => "audio/mpeg"
        };
    }
}

public class GroqRateLimitException : Exception
{
    public GroqRateLimitException() : base("Rate limit exceeded") { }
}
