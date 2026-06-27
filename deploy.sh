#!/usr/bin/env bash
# Aziza Food — local deploy script.
#
# Builds Flutter web on YOUR machine, ships static output to the VPS via
# tar+ssh, triggers a backend update via SSH. The server does NOT compile
# Flutter (its 3.8 GB RAM is shared with other tenants — Flutter compile
# would starve them).
#
# Requires: flutter, ssh, tar (Git Bash on Windows ships these).
# Usage:    ./deploy.sh
set -euo pipefail

SERVER="${AZIZA_SERVER:-root@92.51.44.138}"
DOMAIN="${AZIZA_DOMAIN:-food.telegbot3td.ru}"
REMOTE_WEB="/var/www/aziza"
REMOTE_REPO="/root/aziza"
APP=app
BUILD=$APP/build/web
FLUTTER="${FLUTTER:-flutter}"

step() { printf "\n\033[1m==> %s\033[0m\n" "$*"; }

step "1/5  flutter pub get"
( cd "$APP" && "$FLUTTER" pub get >/dev/null )

step "2/5  Building 3 web bundles locally"
TMP=$(mktemp -d -t aziza-deploy.XXXXXX)
trap 'rm -rf "$TMP"' EXIT
build_one() {
  local target="$1" out="$2" href="$3"
  echo "    → $out"
  ( cd "$APP" && MSYS_NO_PATHCONV=1 "$FLUTTER" build web --release --target="lib/$target" --base-href="$href" --no-tree-shake-icons ) >/dev/null
  cp -r "$BUILD" "$TMP/$out"
  rm -rf "$BUILD"
  test -f "$TMP/$out/main.dart.js" || { echo "FAIL: main.dart.js missing in $out"; exit 1; }
  echo "      $(stat -c%s "$TMP/$out/main.dart.js" 2>/dev/null || stat -f%z "$TMP/$out/main.dart.js") bytes main.dart.js"
}
build_one main_client.dart  client  /client/
# admin + courier are fast vanilla-JS apps now (no Flutter build) — ship as-is.
cp -r web/admin   "$TMP/admin"
cp -r web/courier "$TMP/courier"
cp landing/index.html "$TMP/index.html"

step "3/5  Shipping to $SERVER:$REMOTE_WEB (tar+ssh)"
( cd "$TMP" && tar czf - . ) | ssh "$SERVER" "rm -rf $REMOTE_WEB/*; tar xzf - -C $REMOTE_WEB/; chown -R www-data:www-data $REMOTE_WEB"

step "4/5  Pulling backend changes + restarting API"
ssh "$SERVER" "$REMOTE_REPO/redeploy.sh"

step "5/5  Smoke test"
fail=0
for path in / /client/ /admin/ /courier/ /client/main.dart.js /api/v1/health; do
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 20 "https://$DOMAIN$path")
  printf "    %s  https://%s%s\n" "$code" "$DOMAIN" "$path"
  [ "$code" = "200" ] || fail=1
done
[ $fail -eq 0 ] || { echo "Some endpoints returned non-200 — investigate." >&2; exit 1; }

echo
echo "✓ Live at https://$DOMAIN/"
