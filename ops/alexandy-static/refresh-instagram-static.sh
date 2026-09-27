#!/usr/bin/env bash
# Weekly: scrape Smash Balloon Instagram snapshot, full-rebuild static SEO pages, deploy.
# Cron (Europe/Berlin): 0 3 * * 0  → Sundays 03:00
#
# Disk policy: keep only the live tree at /home/alexandyproductions/static/seo.
# Staging under /opt/alexandy-static/dist-build is deleted after a successful deploy.
# Do not keep a third copy in /opt/alexandy-static/dist — that filled the 150G root
# filesystem (3 × ~25G) on 2026-09-27.
set -euo pipefail

ROOT="/opt/alexandy-static"
LIVE="/home/alexandyproductions/static/seo"
STAGING="${ROOT}/dist-build"
LOCK="/var/lock/alexandy-static-refresh.lock"
LOG_TAG="[alexandy-static-refresh]"
MIN_FREE_GB=35

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export NODE_ENV="${NODE_ENV:-production}"

log() {
  echo "$(date -Is) ${LOG_TAG} $*"
}

free_gb() {
  df -BG --output=avail / | awk 'NR==2 {gsub(/G/,""); print $1}'
}

exec 9>"$LOCK"
if ! flock -n 9; then
  log "another refresh is already running; exiting"
  exit 0
fi

cd "$ROOT"

if [[ ! -f scripts/scrape-instagram.py || ! -f scripts/build.mjs ]]; then
  log "ERROR: missing scripts under ${ROOT}"
  exit 1
fi

# Drop leftover staging trees from previous runs before checking free space.
rm -rf "${ROOT}/dist" "${ROOT}/dist-build"
find "$ROOT" -maxdepth 1 -type d -name 'dist-build-*' -prune -exec rm -rf {} +

AVAIL="$(free_gb)"
if [[ "${AVAIL}" -lt "${MIN_FREE_GB}" ]]; then
  log "ERROR: only ${AVAIL}G free on / (need ${MIN_FREE_GB}G for staging build). Aborting."
  exit 1
fi
log "disk preflight ok — ${AVAIL}G free"

log "exporting Instagram posts from Smash Balloon DB"
php "$ROOT/scripts/export-instagram-from-db.php"

log "building full static inventory -> ${STAGING}"
OUT="$STAGING"
if ! rm -rf "$OUT" 2>/dev/null; then
  OUT="${STAGING}-$(date +%Y%m%d%H%M%S)"
  log "could not clear ${STAGING}; using ${OUT}"
fi
node scripts/build.mjs --mode full --out "$OUT"

log "building city hubs into ${OUT}"
node scripts/build-city.mjs --all --out "$OUT" --skip-assets

if [[ -f scripts/patch-de-money-seo.mjs ]]; then
  log "applying DE money-page title/H1/lead templates"
  node scripts/patch-de-money-seo.mjs --root "$OUT" --all-cities
fi

log "deploying to ${LIVE}"
mkdir -p "$LIVE"
rsync -a --delete \
  --exclude 'nginx/' \
  --exclude 'deploy/' \
  "$OUT"/ "$LIVE"/

chown -R alexandyproductions:alexandyproductions /home/alexandyproductions/static

log "removing staging tree ${OUT}"
rm -rf "$OUT"
# Catch timestamped fallback dirs from a busy unlink
find "$ROOT" -maxdepth 1 -type d -name 'dist-build-*' -prune -exec rm -rf {} +

PAGES=$(find "$LIVE" -type f -name index.html 2>/dev/null | wc -l | tr -d ' ')
log "done — ${PAGES} index.html pages live; $(free_gb)G free"
