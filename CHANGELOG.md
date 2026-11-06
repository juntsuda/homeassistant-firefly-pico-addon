# Changelog

## 1.12.1

- Upgrade the wrapped upstream image to `cioraneanu/firefly-pico:1.12.1` (patch release: bug fixes for split transactions, the account selector, dark-mode notes, virtual balance display, Greek translation; image rebased on Alpine 3.24 / PHP 8.4). Add-on wrapper unchanged: nginx still listens on port 80 inside the container.

## 1.12.0

- Initial release: wraps upstream `cioraneanu/firefly-pico:1.12.0`, points at an existing
  Firefly III instance via the `firefly_url` option, persists the SQLite database under
  the add-on's own `/data`, and optionally forwards Ramble (AI assistant) settings.
- Fixed: every supervisor-managed process (nginx, php-fpm, redis, cron, horizon) failed
  to start with `EACCES` reopening `/dev/stdout` when the entrypoint dropped to the
  image's `www-data` user before launching `supervisord`. Fix: run `supervisord` as
  root (each program still drops to `www-data` via its own `user=` directive), and
  redirect nginx's own `/dev/stdout`/`/dev/stderr` log paths to real files, tailed into
  the container's stdout — nginx reopens those paths itself, at its own (non-root)
  privilege level, so the supervisord-level fix alone didn't cover it.
