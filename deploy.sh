#!/usr/bin/env bash
# Aziza Food — deploy script (static, no build step).
#
# client / admin / courier are now fast vanilla-JS apps under web/. We just
# ship them to the VPS via tar+ssh and trigger a backend update via SSH.
# (No Flutter SDK required anymore — the old ~3MB Flutter bundles were slow
# and have been replaced.)
#
# Requires: ssh, tar, curl (Git Bash on Windows ships these).
# Usage:    ./deploy.sh
set -euo pipefail

SERVER="${AZIZA_SERVER:-root@92.51.44.138}"
DOMAIN="${AZIZA_DOMAIN:-food.netchess.ru}"
REMOTE_WEB="/var/www/aziza"
REMOTE_REPO="/root/aziza"

step() { printf "\n\033[1m==> %s\033[0m\n" "$*"; }

[ -f web/client/index.html ]  || { echo "FAIL: web/client missing";  exit 1; }
[ -f web/admin/index.html ]   || { echo "FAIL: web/admin missing";   exit 1; }
[ -f web/courier/index.html ] || { echo "FAIL: web/courier missing"; exit 1; }

step "1/4  Assembling static bundles"
TMP=$(mktemp -d -t aziza-deploy.XXXXXX)
trap 'rm -rf "$TMP"' EXIT
cp -r web/client  "$TMP/client"
cp -r web/admin   "$TMP/admin"
cp -r web/courier "$TMP/courier"
cp landing/index.html "$TMP/index.html"

step "2/4  Backing up live web root + shipping (tar+ssh)"
( cd "$TMP" && tar czf - . ) | ssh "$SERVER" "
  cp -a $REMOTE_WEB ${REMOTE_WEB}.bak.\$(date +%s) 2>/dev/null || true
  rm -rf $REMOTE_WEB/*
  tar xzf - -C $REMOTE_WEB/
  chown -R www-data:www-data $REMOTE_WEB
"

step "3/4  Pulling backend changes + restarting API"
ssh "$SERVER" "$REMOTE_REPO/redeploy.sh"

step "4/4  Smoke test"
fail=0
for path in / /client/ /admin/ /courier/ /client/app.js /api/v1/health; do
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 20 "https://$DOMAIN$path")
  printf "    %s  https://%s%s\n" "$code" "$DOMAIN" "$path"
  [ "$code" = "200" ] || fail=1
done
[ $fail -eq 0 ] || { echo "Some endpoints returned non-200 — investigate." >&2; exit 1; }

echo
echo "✓ Live at https://$DOMAIN/"
