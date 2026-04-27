#!/usr/bin/env bash
# Builds all three Flutter web apps + assembles landing page into ./public/
# for Netlify to publish.
#
# We git-clone Flutter's stable channel (smaller + Flutter relies on .git for
# version tracking; tarball approach hits known precache issues on CI).
set -eo pipefail
set -x

FLUTTER_VERSION="${FLUTTER_VERSION:-stable}"
SDK_DIR="$HOME/flutter"

echo "==> Installing Flutter ($FLUTTER_VERSION)"
if [ ! -d "$SDK_DIR/bin" ]; then
  git clone --depth 1 -b "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$SDK_DIR"
fi
export PATH="$SDK_DIR/bin:$PATH"
git config --global --add safe.directory "$SDK_DIR"
flutter --version
flutter config --no-analytics --enable-web

echo "==> Resolving Flutter dependencies"
cd app
flutter pub get

PUB="../public"
rm -rf "$PUB"
mkdir -p "$PUB"

build_app() {
  local target="$1"
  local out="$2"
  local href="$3"
  echo "==> Building $out"
  flutter build web --release --target="lib/$target" --base-href="$href" --no-tree-shake-icons
  cp -r build/web "$PUB/$out"
  rm -rf build/web
}

build_app "main_client.dart"  "client"  "/client/"
build_app "main_admin.dart"   "admin"   "/admin/"
build_app "main_courier.dart" "courier" "/courier/"

echo "==> Copying landing page"
cp deploy/index.html "$PUB/"

echo "==> Done. Sizes:"
du -sh "$PUB"/*
