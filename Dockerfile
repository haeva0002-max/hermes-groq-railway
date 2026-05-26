FROM python:3.11-bookworm

RUN apt-get update && apt-get install -y \
    git curl nodejs npm build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Клонируем Hermes
RUN git clone --depth 1 --recurse-submodules https://github.com/NousResearch/hermes-agent.git .

# Устанавливаем пакет hermes
RUN pip install --no-cache-dir --editable .

# Устанавливаем основные зависимости
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir \
    groq \
    python-telegram-bot \
    fastapi \
    uvicorn \
    pydantic \
    aiohttp \
    requests

# Удаляем локальные зависимости из requirements или setup.py
RUN if [ -f setup.py ]; then \
        # Попытаемся установить без локальных зависимостей
        pip install --no-cache-dir --no-deps . || true; \
    fi && \
    if [ -f requirements.txt ]; then \
        # Удаляем строки с локальными path зависимостями
        grep -v "^\./" requirements.txt | grep -v "^-e \." > requirements_clean.txt && \
        pip install --no-cache-dir -r requirements_clean.txt || true; \
    fi

# Node зависимости (опционально)
RUN npm install 2>/dev/null || true

ENV GROQ_API_KEY=""
ENV LLM_MODEL="groq/llama-3.3-70b-versatile"
ENV TELEGRAM_BOT_TOKEN=""
ENV GATEWAY_ALLOW_ALL_USERS="true"
ENV PORT=7860

# Запускаем Python приложение (замени на правильную точку входа)
CMD ["python", "-m", "hermes.gateway"]
