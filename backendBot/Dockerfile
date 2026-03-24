FROM python:3.12-slim

WORKDIR /app

# Install dependencies first (cached layer)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create data directory for SQLite
RUN mkdir -p /app/data

# Koyeb uses PORT env variable (default 8080)
ENV PORT=8080

EXPOSE 8080

CMD ["python", "main.py"]
