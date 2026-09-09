#!/usr/bin/env bash
set -u

CONFIG_PATH=/data/options.json

opt() {
  jq -r --arg k "$1" '.[$k] // empty' "$CONFIG_PATH"
}

export FIREFLY_URL="$(opt firefly_url)"
export TZ="$(opt timezone)"

# Optional Ramble (AI assistant) settings: only export what's actually set,
# so the app's own defaults (e.g. OpenAI endpoint) apply when left blank.
for pair in \
  ASSISTANT_LLM_ENDPOINT:assistant_llm_endpoint \
  ASSISTANT_LLM_MODEL:assistant_llm_model \
  ASSISTANT_LLM_API_KEY:assistant_llm_api_key \
  ASSISTANT_LLM_CONTEXT:assistant_llm_context \
  ASSISTANT_TRANSCRIPTION_ENDPOINT:assistant_transcription_endpoint \
  ASSISTANT_TRANSCRIPTION_MODEL:assistant_transcription_model \
  ASSISTANT_TRANSCRIPTION_API_KEY:assistant_transcription_api_key \
  ASSISTANT_TRANSCRIPTION_LANGUAGE:assistant_transcription_language
do
  env_name="${pair%%:*}"
  opt_name="${pair#*:}"
  value="$(opt "$opt_name")"
  if [ -n "$value" ]; then
    export "$env_name"="$value"
  fi
done

# Persist the SQLite database in the add-on's own /data (survives updates/rebuilds)
# instead of the upstream image's default in-container path.
mkdir -p /data/database
rm -rf /var/www/html/database/data
ln -s /data/database /var/www/html/database/data
chown -R www-data:www-data /data/database

exec su-exec www-data /docker-entrypoint.d/start.sh run
