FROM python:3.11-bookworm

RUN apt-get update && apt-get install -y \
    git curl nodejs npm build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Клонируем Hermes
RUN git clone --depth 1 --recurse-submodules https://github.com/NousResearch/hermes-agent.git .

# Устанавливаем основные зависимости
RUN pip install --no-cache-dir \
    groq \
    python-telegram-bot \
    fastapi \
    uvicorn \
    pydantic \
    aiohttp \
    requests

# Пытаемся установить локально если есть setup.py
RUN if [ -f setup.py ]; then pip install --no-cache-dir -e .; elif [ -f pyproject.toml ]; then pip install --no-cache-dir -e .; fi || true

# Node зависимости (опционально)
RUN npm install 2>/dev/null || true

ENV GROQ_API_KEY=""
ENV LLM_MODEL="groq/llama-3.3-70b-versatile"
ENV TELEGRAM_BOT_TOKEN=""
ENV GATEWAY_ALLOW_ALL_USERS="true"
ENV PORT=7860

# Запускаем Python приложение (замени на правильную точку входа)
CMD ["python", "-m", "hermes.gateway"]
