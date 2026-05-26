FROM python:3.11-slim

WORKDIR /app

# System deps for psycopg + pgvector
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev gcc && rm -rf /var/lib/apt/lists/*

COPY requirements.txt pyproject.toml ./
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ ./src/
RUN pip install --no-cache-dir -e .

EXPOSE 8000
CMD ["uvicorn", "party_agent.api.main:app", "--host", "0.0.0.0", "--port", "8000"]
