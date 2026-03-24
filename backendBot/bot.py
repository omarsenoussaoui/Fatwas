import logging
from telegram import Update
from telegram.ext import (
    Application,
    CommandHandler,
    MessageHandler,
    ContextTypes,
    filters,
)
from config import (
    SHEIKH_NAME,
    GROQ_MAX_FILE_SIZE,
    TELEGRAM_MAX_MESSAGE_LENGTH,
)
from database import save_transcription, get_history, get_user_stats, get_global_stats
from transcriber import transcribe_audio, TranscriptionError

logger = logging.getLogger(__name__)


# ──────────────────────────────────────────────
# Command handlers
# ──────────────────────────────────────────────

async def start_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Send welcome message on /start."""
    text = (
        "بسم الله الرحمن الرحيم\n\n"
        f"📚 *فتاوى {SHEIKH_NAME}*\n\n"
        "مرحباً بك في بوت تفريغ الفتاوى الصوتية\\.\n\n"
        "🎙️ أرسل أو أعد توجيه رسالة صوتية أو ملف صوتي وسأقوم بتحويلها إلى نص مكتوب\\.\n\n"
        "📋 *الأوامر المتاحة:*\n"
        "/start \\- رسالة الترحيب\n"
        "/help \\- المساعدة\n"
        "/history \\- آخر 10 تفريغات\n"
        "/stats \\- الإحصائيات"
    )
    await update.message.reply_text(text, parse_mode="MarkdownV2")


async def help_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Send help message on /help."""
    text = (
        f"📖 *كيفية الاستخدام:*\n\n"
        "1️⃣ أرسل رسالة صوتية مباشرة\n"
        "2️⃣ أو أعد توجيه رسالة صوتية من محادثة أخرى\n"
        "3️⃣ أو أرسل ملف صوتي \\(MP3, WAV, M4A, OGG\\)\n\n"
        "سأقوم بتحويل الصوت إلى نص عربي مكتوب\\.\n\n"
        f"📌 هذا البوت مخصص لتفريغ فتاوى *{_escape_md(SHEIKH_NAME)}*"
    )
    await update.message.reply_text(text, parse_mode="MarkdownV2")


async def history_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Show last 10 transcriptions on /history."""
    user_id = update.effective_user.id
    history = get_history(user_id, limit=10)

    if not history:
        await update.message.reply_text("📭 لا توجد تفريغات سابقة بعد.")
        return

    text = "📋 *آخر التفريغات:*\n\n"
    for i, item in enumerate(history, 1):
        date = item["created_at"][:10]
        duration = _format_duration(item.get("duration", 0))
        preview = item["transcription"][:80]
        if len(item["transcription"]) > 80:
            preview += "..."
        name = item.get("file_name") or "صوتية"

        text += f"*{i}\\.* {_escape_md(name)}\n"
        text += f"   📅 {_escape_md(date)} \\| ⏱️ {_escape_md(duration)}\n"
        text += f"   {_escape_md(preview)}\n\n"

    await update.message.reply_text(text, parse_mode="MarkdownV2")


async def stats_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Show user and global stats on /stats."""
    user_id = update.effective_user.id
    user_stats = get_user_stats(user_id)
    global_stats = get_global_stats()

    user_duration = _format_duration(user_stats["total_duration"])
    global_duration = _format_duration(global_stats["total_duration"])

    text = (
        "📊 *إحصائياتك:*\n"
        f"   عدد التفريغات: {user_stats['total_count']}\n"
        f"   إجمالي المدة: {_escape_md(user_duration)}\n"
        f"   إجمالي الحروف: {user_stats['total_chars']}\n\n"
        "🌍 *إحصائيات البوت:*\n"
        f"   إجمالي التفريغات: {global_stats['total_count']}\n"
        f"   عدد المستخدمين: {global_stats['total_users']}\n"
        f"   إجمالي المدة: {_escape_md(global_duration)}"
    )
    await update.message.reply_text(text, parse_mode="MarkdownV2")


# ──────────────────────────────────────────────
# Audio message handlers
# ──────────────────────────────────────────────

async def handle_voice(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle voice messages."""
    voice = update.message.voice
    await _process_audio(
        update,
        context,
        file_id=voice.file_id,
        file_name="voice_message.ogg",
        duration=voice.duration or 0,
        file_size=voice.file_size,
    )


async def handle_audio(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle audio file messages."""
    audio = update.message.audio
    await _process_audio(
        update,
        context,
        file_id=audio.file_id,
        file_name=audio.file_name or f"audio.{audio.mime_type.split('/')[-1] if audio.mime_type else 'mp3'}",
        duration=audio.duration or 0,
        file_size=audio.file_size,
    )


async def handle_document(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle document messages that are audio files."""
    doc = update.message.document
    mime = doc.mime_type or ""

    if not mime.startswith("audio/"):
        await update.message.reply_text(
            "⚠️ هذا الملف ليس ملف صوتي.\n"
            "أرسل ملف صوتي (MP3, WAV, M4A, OGG) أو رسالة صوتية."
        )
        return

    await _process_audio(
        update,
        context,
        file_id=doc.file_id,
        file_name=doc.file_name or "document_audio",
        duration=0,
        file_size=doc.file_size,
    )


async def handle_video_note(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle video notes (circle messages) — extract audio."""
    vn = update.message.video_note
    await _process_audio(
        update,
        context,
        file_id=vn.file_id,
        file_name="video_note.mp4",
        duration=vn.duration or 0,
        file_size=vn.file_size,
    )


async def handle_other(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle non-audio messages."""
    await update.message.reply_text(
        "🎙️ أرسل رسالة صوتية أو ملف صوتي لتحويله إلى نص.\n"
        "اكتب /help للمساعدة."
    )


# ──────────────────────────────────────────────
# Core processing
# ──────────────────────────────────────────────

async def _process_audio(
    update: Update,
    context: ContextTypes.DEFAULT_TYPE,
    file_id: str,
    file_name: str,
    duration: int,
    file_size: int | None,
):
    """Download audio from Telegram, transcribe via Groq, reply with text."""
    user = update.effective_user

    # Check file size
    if file_size and file_size > GROQ_MAX_FILE_SIZE:
        size_mb = file_size / (1024 * 1024)
        await update.message.reply_text(
            f"⚠️ الملف كبير جداً ({size_mb:.1f} ميغابايت).\n"
            "الحد الأقصى هو 25 ميغابايت."
        )
        return

    # Show typing indicator
    await context.bot.send_chat_action(chat_id=update.effective_chat.id, action="typing")

    # Send "processing" message
    duration_str = _format_duration(duration) if duration > 0 else ""
    processing_text = f"⏳ جاري تحويل الصوت إلى نص..."
    if duration_str:
        processing_text += f"\n⏱️ مدة الملف: {duration_str}"
    status_msg = await update.message.reply_text(processing_text)

    try:
        # Download file from Telegram
        file = await context.bot.get_file(file_id)
        file_bytes = await file.download_as_bytearray()

        # Transcribe
        transcription = await transcribe_audio(bytes(file_bytes), file_name)

        # Save to database
        save_transcription(
            user_id=user.id,
            username=user.username,
            first_name=user.first_name,
            file_name=file_name,
            duration=duration,
            transcription=transcription,
        )

        # Delete the processing message
        await status_msg.delete()

        # Send transcription (handle Telegram's 4096 char limit)
        await _send_long_text(update, transcription)

    except TranscriptionError as e:
        await status_msg.edit_text(f"❌ {e}")

    except Exception as e:
        logger.exception("Unexpected error during transcription")
        await status_msg.edit_text(
            "❌ حدث خطأ غير متوقع. حاول مرة أخرى.\n"
            "إذا استمرت المشكلة، جرب إرسال الملف مرة أخرى."
        )


async def _send_long_text(update: Update, text: str):
    """Send text, splitting into multiple messages if it exceeds Telegram's limit."""
    header = f"📝 *{_escape_md(SHEIKH_NAME)}*\n\n"

    if len(header) + len(text) <= TELEGRAM_MAX_MESSAGE_LENGTH:
        await update.message.reply_text(
            header + _escape_md(text),
            parse_mode="MarkdownV2",
        )
        return

    # Split into chunks
    chunks = _split_text(text, TELEGRAM_MAX_MESSAGE_LENGTH - 50)

    for i, chunk in enumerate(chunks):
        if i == 0:
            msg = header + _escape_md(chunk)
        else:
            msg = _escape_md(chunk)

        await update.message.reply_text(msg, parse_mode="MarkdownV2")


def _split_text(text: str, max_len: int) -> list[str]:
    """Split text into chunks, preferring to break at newlines or sentences."""
    chunks = []
    while text:
        if len(text) <= max_len:
            chunks.append(text)
            break

        # Try to break at a newline
        split_pos = text.rfind("\n", 0, max_len)
        if split_pos == -1:
            # Try to break at a period/sentence end
            split_pos = text.rfind(".", 0, max_len)
        if split_pos == -1:
            # Try space
            split_pos = text.rfind(" ", 0, max_len)
        if split_pos == -1:
            split_pos = max_len

        chunks.append(text[: split_pos + 1])
        text = text[split_pos + 1 :].lstrip()

    return chunks


def _format_duration(seconds: int) -> str:
    """Format seconds into MM:SS or HH:MM:SS."""
    if seconds <= 0:
        return "0:00"
    hours = seconds // 3600
    minutes = (seconds % 3600) // 60
    secs = seconds % 60
    if hours > 0:
        return f"{hours}:{minutes:02d}:{secs:02d}"
    return f"{minutes}:{secs:02d}"


def _escape_md(text: str) -> str:
    """Escape special characters for Telegram MarkdownV2."""
    special = r"_*[]()~`>#+-=|{}.!"
    result = ""
    for ch in text:
        if ch in special:
            result += f"\\{ch}"
        else:
            result += ch
    return result


# ──────────────────────────────────────────────
# Register all handlers
# ──────────────────────────────────────────────

def register_handlers(app: Application):
    """Register all command and message handlers."""
    # Commands
    app.add_handler(CommandHandler("start", start_command))
    app.add_handler(CommandHandler("help", help_command))
    app.add_handler(CommandHandler("history", history_command))
    app.add_handler(CommandHandler("stats", stats_command))

    # Audio messages
    app.add_handler(MessageHandler(filters.VOICE, handle_voice))
    app.add_handler(MessageHandler(filters.AUDIO, handle_audio))
    app.add_handler(MessageHandler(filters.VIDEO_NOTE, handle_video_note))
    app.add_handler(MessageHandler(filters.Document.ALL, handle_document))

    # Everything else
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_other))
    app.add_handler(MessageHandler(filters.PHOTO | filters.VIDEO | filters.Sticker.ALL, handle_other))
