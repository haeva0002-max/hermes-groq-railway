FROM python:3.11-slim

RUN apt-get update && apt-get install -y git curl nodejs npm && rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN git clone --depth 1 --recurse-submodules https://github.com/NousResearch/hermes-agent.git .

RUN pip install -e ".[all]" -e "./tinker-atropos"

ENV GROQ_API_KEY=""
ENV LLM_MODEL="groq/llama-3.3-70b-versatile"
ENV TELEGRAM_BOT_TOKEN=""
ENV GATEWAY_ALLOW_ALL_USERS="true"
ENV PORT=7860

CMD ["hermes", "gateway", "run"]

