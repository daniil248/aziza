#!/usr/bin/env bash
# Builds all three Flutter web apps + assembles landing page into ./public/
# for Netlify to publish.
#
# Total build time on Netlify: ~5-7 minutes (Flutter SDK download dominates).
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.41.7}"
SDK_DIR="$HOME/flutter"

echo "==> Installing Flutter $FLUTTER_VERSION"
if [ ! -d "$SDK_DIR" ]; then
  curl -fsSL -o /tmp/flutter.tar.xz \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
  tar -xf /tmp/flutter.tar.xz -C "$HOME"
fi
export PATH="$SDK_DIR/bin:$PATH"
flutter --version
flutter config --no-analytics
flutter precache --web

echo "==> Resolving Flutter dependencies"
cd app
flutter pub get
flutter gen-l10n

PUB="../public"
rm -rf "$PUB"
mkdir -p "$PUB"

echo "==> Building client app"
flutter build web --release --target=lib/main_client.dart --base-href=/client/
cp -r build/web "$PUB/client"
rm -rf build/web

echo "==> Building admin app"
flutter build web --release --target=lib/main_admin.dart --base-href=/admin/
cp -r build/web "$PUB/admin"
rm -rf build/web

echo "==> Building courier app"
flutter build web --release --target=lib/main_courier.dart --base-href=/courier/
cp -r build/web "$PUB/courier"
rm -rf build/web

echo "==> Copying landing page"
cp deploy/index.html "$PUB/"

echo "==> Done. Sizes:"
du -sh "$PUB"/*
