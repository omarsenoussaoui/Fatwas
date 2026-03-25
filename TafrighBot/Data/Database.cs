using Dapper;
using Microsoft.Data.Sqlite;
using TafrighBot.Models;

namespace TafrighBot.Data;

public class Database
{
    private readonly string _connectionString;

    public Database(string dbPath)
    {
        var dir = Path.GetDirectoryName(dbPath);
        if (!string.IsNullOrEmpty(dir) && !Directory.Exists(dir))
            Directory.CreateDirectory(dir);

        _connectionString = $"Data Source={dbPath}";
        InitializeAsync().GetAwaiter().GetResult();
    }

    private async Task InitializeAsync()
    {
        using var conn = new SqliteConnection(_connectionString);
        await conn.OpenAsync();
        await conn.ExecuteAsync(@"
            CREATE TABLE IF NOT EXISTS transcriptions (
                Id INTEGER PRIMARY KEY AUTOINCREMENT,
                TelegramUserId INTEGER NOT NULL,
                UserName TEXT NOT NULL DEFAULT '',
                FileName TEXT NOT NULL DEFAULT '',
                DurationSeconds INTEGER NOT NULL DEFAULT 0,
                Text TEXT NOT NULL DEFAULT '',
                CreatedAt TEXT NOT NULL DEFAULT (datetime('now'))
            )
        ");
        await conn.ExecuteAsync(@"
            CREATE TABLE IF NOT EXISTS users (
                TelegramUserId INTEGER PRIMARY KEY,
                FirstSeenAt TEXT NOT NULL DEFAULT (datetime('now'))
            )
        ");
    }

    public async Task<long> SaveTranscriptionAsync(Transcription t)
    {
        using var conn = new SqliteConnection(_connectionString);
        await conn.OpenAsync();
        return await conn.ExecuteScalarAsync<long>(@"
            INSERT INTO transcriptions (TelegramUserId, UserName, FileName, DurationSeconds, Text, CreatedAt)
            VALUES (@TelegramUserId, @UserName, @FileName, @DurationSeconds, @Text, @CreatedAt);
            SELECT last_insert_rowid();
        ", t);
    }

    public async Task<IEnumerable<Transcription>> GetHistoryAsync(long userId, int limit = 10)
    {
        using var conn = new SqliteConnection(_connectionString);
        await conn.OpenAsync();
        return await conn.QueryAsync<Transcription>(@"
            SELECT * FROM transcriptions
            WHERE TelegramUserId = @userId
            ORDER BY CreatedAt DESC
            LIMIT @limit
        ", new { userId, limit });
    }

    public async Task<(int userCount, int totalCount)> GetStatsAsync(long userId)
    {
        using var conn = new SqliteConnection(_connectionString);
        await conn.OpenAsync();

        var userCount = await conn.ExecuteScalarAsync<int>(
            "SELECT COUNT(*) FROM transcriptions WHERE TelegramUserId = @userId",
            new { userId });

        var totalCount = await conn.ExecuteScalarAsync<int>(
            "SELECT COUNT(*) FROM transcriptions");

        return (userCount, totalCount);
    }

    /// Returns true if this is the first time the user uses the bot
    public async Task<bool> IsFirstUseAsync(long userId)
    {
        using var conn = new SqliteConnection(_connectionString);
        await conn.OpenAsync();
        var exists = await conn.ExecuteScalarAsync<int>(
            "SELECT COUNT(*) FROM users WHERE TelegramUserId = @userId",
            new { userId });

        if (exists == 0)
        {
            await conn.ExecuteAsync(
                "INSERT INTO users (TelegramUserId) VALUES (@userId)",
                new { userId });
            return true;
        }
        return false;
    }
}
