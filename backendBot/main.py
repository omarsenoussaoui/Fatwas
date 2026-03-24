import logging
from telegram.ext import Application
from config import TELEGRAM_BOT_TOKEN, WEBHOOK_URL, WEBHOOK_PATH, PORT
from database import init_db
from bot import register_handlers

# Logging
logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    level=logging.INFO,
)
logger = logging.getLogger(__name__)


def main():
    if not TELEGRAM_BOT_TOKEN:
        logger.error("TELEGRAM_BOT_TOKEN environment variable is not set!")
        return

    # Initialize database
    init_db()
    logger.info("Database initialized")

    # Build the bot application
    app = Application.builder().token(TELEGRAM_BOT_TOKEN).build()

    # Register all handlers
    register_handlers(app)
    logger.info("Handlers registered")

    # Run with webhook (for Koyeb/production) or polling (for local dev)
    if WEBHOOK_URL:
        webhook_url = f"{WEBHOOK_URL}{WEBHOOK_PATH}"
        logger.info(f"Starting webhook on port {PORT} -> {webhook_url}")
        app.run_webhook(
            listen="0.0.0.0",
            port=PORT,
            url_path=WEBHOOK_PATH,
            webhook_url=webhook_url,
        )
    else:
        logger.info("No WEBHOOK_URL set, starting in polling mode (local dev)")
        app.run_polling(drop_pending_updates=True)


if __name__ == "__main__":
    main()
