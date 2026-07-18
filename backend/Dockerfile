FROM nvidia/cuda:12.2.2-base-ubuntu22.04

WORKDIR /app

# Install Python, pip, curl, and zstd
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    python3 python3-pip curl pciutils zstd && \
    rm -rf /var/lib/apt/lists/*

# Install Ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

# Pre-pull the model during build to avoid cold-start downloads
ENV OLLAMA_MODELS=/usr/share/ollama/.ollama/models
RUN ollama serve & \
    sleep 5 && \
    ollama pull gemma3:4b

# Install Python dependencies
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Run both Ollama and Uvicorn
CMD ["sh", "-c", "ollama serve & python3 -m uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}"]
