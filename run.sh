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

# Run the original entrypoint (and supervisord) as root, not su-exec'd to www-data:
# every supervisor-managed program uses stdout_logfile=/dev/stdout, and reopening that
# path by a non-root process fails with EACCES under this container runtime. Each
# program still drops to www-data itself via its own `user=www-data` directive in
# /etc/supervisor.d/*.ini — this only changes who runs supervisord's own dispatcher
# setup, not the actual app processes' privileges.
#
# nginx hits the same EACCES itself: its own config re-opens /dev/stdout and
# /dev/stderr by path (nginx.conf's access_log/error_log directives) at its own
# process's (www-data) privilege level, since supervisord already dropped to
# www-data before exec'ing it. Redirect those to real files instead and tail them
# into our own (root-held, already-open) stdout so `docker logs` still shows them.
mkdir -p /tmp/nginx
: > /tmp/nginx/access.log
: > /tmp/nginx/error.log
chown www-data:www-data /tmp/nginx/access.log /tmp/nginx/error.log
sed -i 's#access_log /dev/stdout#access_log /tmp/nginx/access.log#' /etc/nginx/nginx.conf
sed -i 's#error_log /dev/stderr#error_log /tmp/nginx/error.log#' /etc/nginx/nginx.conf
tail -F /tmp/nginx/access.log /tmp/nginx/error.log &

exec /docker-entrypoint.d/start.sh run
