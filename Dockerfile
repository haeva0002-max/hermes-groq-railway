FROM python:3.11-bookworm

RUN apt-get update && apt-get install -y \
    git curl nodejs npm build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Клонируем Hermes
RUN git clone --depth 1 --recurse-submodules https://github.com/NousResearch/hermes-agent.git .

# Устанавливаем Python зависимости
RUN pip install --no-cache-dir -e ".[all]" || true
RUN pip install --no-cache-dir -e "./tinker-atropos" || true

# Node зависимости (опционально)
RUN npm install || true

ENV GROQ_API_KEY=""
ENV LLM_MODEL="groq/llama-3.3-70b-versatile"
ENV TELEGRAM_BOT_TOKEN=""
ENV GATEWAY_ALLOW_ALL_USERS="true"
ENV PORT=7860

CMD ["hermes", "gateway", "run"]

