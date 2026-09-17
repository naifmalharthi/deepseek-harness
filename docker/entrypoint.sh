#!/bin/sh
set -e
: "${DSH_HOME:=/home/node/.dsh}"
mkdir -p "$DSH_HOME"
if [ ! -f "$DSH_HOME/settings.yaml" ]; then
  cat > "$DSH_HOME/settings.yaml" <<'EOF'
llm-pi-ai:
  providers:
    ollama:
      displayName: ollama
      api: openai-completions
      baseURL: http://host.docker.internal:11434/v1
      apiKeyEnv: OLLAMA_API_KEY
      models:
        - id: qwen3.8:27b
          name: qwen3.8:27b
        - id: edtorre/qwen3.6-hermes:latest
          name: Qwen3.6 Hermes
        - id: qwen3.6:35b
          name: qwen3.6:35b
agent-default-model:
  provider: ollama
  model: qwen3.8:27b
EOF
  echo "dsh-entrypoint: settings.yaml seeded"
else
  echo "dsh-entrypoint: settings.yaml exists - untouched"
fi
exec "$@"
