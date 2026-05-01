# Nightride AI agent — production container
# Build:  docker build -t nightride-agent .
# Run:    docker run -p 8765:8765 --env-file .env nightride-agent
FROM python:3.12-slim

# System deps for grpc / firestore + curl for healthcheck
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python deps (layer-cached separately from source)
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# App source
COPY . .

# fly.io / Cloud Run inject the listening port via $PORT.
# Default to 8080 in container; locally overrideable.
ENV PORT=8080
EXPOSE 8080

# Service-account JSON path (mounted via secret on fly.io / Cloud Run)
ENV GOOGLE_APPLICATION_CREDENTIALS=/app/firebase_service_account.json

# Health check — fly.io will use this
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD curl -fsS http://localhost:${PORT}/ || exit 1

# Entrypoint decodes FIREBASE_SERVICE_ACCOUNT_B64 (fly secret) into the
# expected JSON file, then launches uvicorn.
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh
CMD ["/app/entrypoint.sh"]
