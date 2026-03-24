import os

# Telegram
TELEGRAM_BOT_TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN", "")
WEBHOOK_URL = os.environ.get("WEBHOOK_URL", "")  # e.g. https://your-app.koyeb.app
WEBHOOK_PATH = "/webhook"
PORT = int(os.environ.get("PORT", "8080"))

# Groq
GROQ_API_KEY = os.environ.get("GROQ_API_KEY", "")
GROQ_MODEL = "whisper-large-v3"
GROQ_LANGUAGE = "ar"
GROQ_MAX_FILE_SIZE = 25 * 1024 * 1024  # 25MB
GROQ_MAX_RETRIES = 3
GROQ_RETRY_DELAY = 3  # seconds

# Telegram message limit
TELEGRAM_MAX_MESSAGE_LENGTH = 4096

# Database
DB_PATH = os.environ.get("DB_PATH", "data/fatwas_bot.db")

# Sheikh info
SHEIKH_NAME = "الشيخ بن حنيفية زين العابدين"
