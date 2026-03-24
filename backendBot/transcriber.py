import asyncio
import logging
import httpx
from config import (
    GROQ_API_KEY,
    GROQ_MODEL,
    GROQ_LANGUAGE,
    GROQ_MAX_RETRIES,
    GROQ_RETRY_DELAY,
)

logger = logging.getLogger(__name__)

GROQ_URL = "https://api.groq.com/openai/v1/audio/transcriptions"


async def transcribe_audio(file_bytes: bytes, file_name: str) -> str:
    """
    Send audio bytes to Groq Whisper API and return the Arabic transcription.
    Includes retry logic for rate limits and server errors.
    """
    headers = {"Authorization": f"Bearer {GROQ_API_KEY}"}

    for attempt in range(GROQ_MAX_RETRIES):
        try:
            async with httpx.AsyncClient(timeout=300) as client:
                response = await client.post(
                    GROQ_URL,
                    headers=headers,
                    files={"file": (file_name, file_bytes, "audio/mpeg")},
                    data={
                        "model": GROQ_MODEL,
                        "language": GROQ_LANGUAGE,
                        "response_format": "json",
                    },
                )

            # Rate limit — wait and retry
            if response.status_code == 429:
                delay = GROQ_RETRY_DELAY * (attempt + 1)
                logger.warning(f"Rate limited, retrying in {delay}s (attempt {attempt + 1})")
                await asyncio.sleep(delay)
                continue

            # Server error — retry
            if response.status_code >= 500:
                delay = GROQ_RETRY_DELAY
                logger.warning(f"Server error {response.status_code}, retrying in {delay}s")
                await asyncio.sleep(delay)
                continue

            # Success
            if response.status_code == 200:
                data = response.json()
                text = data.get("text", "").strip()
                if not text:
                    raise TranscriptionError("لم يتم التعرف على أي كلام في الملف الصوتي")
                return text

            # Client error — don't retry
            error_msg = _parse_error(response)
            raise TranscriptionError(error_msg)

        except httpx.TimeoutException:
            if attempt < GROQ_MAX_RETRIES - 1:
                logger.warning(f"Timeout, retrying (attempt {attempt + 1})")
                await asyncio.sleep(GROQ_RETRY_DELAY)
                continue
            raise TranscriptionError("انتهت مهلة الاتصال بخادم النسخ. حاول مرة أخرى.")

        except httpx.RequestError as e:
            raise TranscriptionError(f"خطأ في الاتصال: {e}")

    raise TranscriptionError("فشل النسخ بعد عدة محاولات. حاول مرة أخرى لاحقاً.")


def _parse_error(response: httpx.Response) -> str:
    """Extract a human-readable error message from the API response."""
    status = response.status_code
    try:
        data = response.json()
        msg = data.get("error", {}).get("message") or data.get("message") or data.get("error")
        if msg:
            return f"{msg} (HTTP {status})"
    except Exception:
        pass

    if status == 400:
        return "الملف الصوتي غير صالح أو بصيغة غير مدعومة"
    if status == 401:
        return "مفتاح API غير صالح"
    if status == 413:
        return "الملف الصوتي كبير جداً (الحد الأقصى 25 ميغابايت)"

    return f"فشل النسخ (HTTP {status})"


class TranscriptionError(Exception):
    """Custom exception for transcription failures with Arabic messages."""
    pass
