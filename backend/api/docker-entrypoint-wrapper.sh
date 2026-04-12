#!/bin/bash
set -e

# Host bind-mount (Windows) may checkout scripts with CRLF; strip before running dev entrypoint.
if [ -d /rails/bin ]; then
  shopt -s nullglob
  for f in /rails/bin/*; do
    sed -i 's/\r$//g' "$f" 2>/dev/null || true
  done
fi

exec /bin/bash /rails/bin/docker-entrypoint-dev "$@"
