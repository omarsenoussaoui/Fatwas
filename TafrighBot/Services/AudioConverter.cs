using System.Diagnostics;

namespace TafrighBot.Services;

public class AudioConverter
{
    private const long GroqMaxSize = 25 * 1024 * 1024; // 25MB
    private const string TempDir = "/app/temp";
    private readonly ILogger<AudioConverter> _logger;

    public AudioConverter(ILogger<AudioConverter> logger)
    {
        _logger = logger;

        if (!Directory.Exists(TempDir))
            Directory.CreateDirectory(TempDir);
    }

    /// <summary>
    /// Takes raw audio/video bytes, extracts and compresses audio to mp3.
    /// Returns compressed bytes under 25MB ready for Groq API.
    /// If original is already small enough and is audio, returns it as-is.
    /// </summary>
    public async Task<(byte[] data, string fileName)> CompressForGroqAsync(
        byte[] inputData, string originalFileName)
    {
        // If already small enough and is an audio format, skip conversion
        if (inputData.Length <= GroqMaxSize && IsSimpleAudio(originalFileName))
        {
            _logger.LogInformation("File {Name} is {Size}KB - no conversion needed",
                originalFileName, inputData.Length / 1024);
            return (inputData, originalFileName);
        }

        _logger.LogInformation("Converting {Name} ({Size}MB) with ffmpeg...",
            originalFileName, inputData.Length / 1024 / 1024);

        var inputId = Guid.NewGuid().ToString("N");
        var inputPath = Path.Combine(TempDir, $"{inputId}{Path.GetExtension(originalFileName)}");
        var outputPath = Path.Combine(TempDir, $"{inputId}_out.mp3");

        try
        {
            // Write input to temp file
            await File.WriteAllBytesAsync(inputPath, inputData);

            // Try 64kbps first (very small, good enough for speech)
            if (await TryConvert(inputPath, outputPath, "64k"))
            {
                var result = await File.ReadAllBytesAsync(outputPath);
                if (result.Length <= GroqMaxSize)
                {
                    _logger.LogInformation("Converted to {Size}KB at 64kbps", result.Length / 1024);
                    return (result, $"{Path.GetFileNameWithoutExtension(originalFileName)}.mp3");
                }
            }

            // If still too big, try 32kbps (minimum quality, still works for speech)
            CleanFile(outputPath);
            if (await TryConvert(inputPath, outputPath, "32k"))
            {
                var result = await File.ReadAllBytesAsync(outputPath);
                if (result.Length <= GroqMaxSize)
                {
                    _logger.LogInformation("Converted to {Size}KB at 32kbps", result.Length / 1024);
                    return (result, $"{Path.GetFileNameWithoutExtension(originalFileName)}.mp3");
                }
            }

            // If STILL too big (very long audio), split is not worth it - just inform user
            throw new InvalidOperationException(
                "❌ الملف كبير جداً حتى بعد الضغط. حاول إرسال ملف أقصر.");
        }
        finally
        {
            // Clean up temp files
            CleanFile(inputPath);
            CleanFile(outputPath);
        }
    }

    private async Task<bool> TryConvert(string inputPath, string outputPath, string bitrate)
    {
        // ffmpeg command: extract audio, convert to mono mp3, specified bitrate
        var args = $"-i \"{inputPath}\" -vn -ac 1 -ar 16000 -b:a {bitrate} -y \"{outputPath}\"";

        var process = new Process
        {
            StartInfo = new ProcessStartInfo
            {
                FileName = "ffmpeg",
                Arguments = args,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true
            }
        };

        try
        {
            process.Start();
            var stderr = await process.StandardError.ReadToEndAsync();
            await process.WaitForExitAsync();

            if (process.ExitCode != 0)
            {
                _logger.LogWarning("ffmpeg failed: {Error}", stderr);
                return false;
            }

            return File.Exists(outputPath) && new FileInfo(outputPath).Length > 0;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "ffmpeg process error");
            return false;
        }
    }

    private static bool IsSimpleAudio(string fileName)
    {
        var ext = Path.GetExtension(fileName).ToLowerInvariant();
        return ext is ".mp3" or ".ogg" or ".oga" or ".m4a" or ".wav" or ".flac" or ".webm";
    }

    private static void CleanFile(string path)
    {
        try { if (File.Exists(path)) File.Delete(path); } catch { }
    }
}
