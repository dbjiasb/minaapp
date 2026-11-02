#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"
flutter_bin="${FLUTTER_BIN:-flutter}"

echo " ------------- Build AAB Release --------------------"
"$flutter_bin" --version

# Resolve first so an incompatible Flutter SDK fails before cleaning the build.
"$flutter_bin" pub get
version=$(awk '/^version:/ {split($2, parts, "+"); print parts[1]; exit}' pubspec.yaml)
symbol_path="./sybol_adr_${version}"

echo 'Start clean'
"$flutter_bin" clean
echo 'Start pub get'
"$flutter_bin" pub get
echo 'Finish pub get'
echo 'Start build Android release (target SDK 36 / Billing 8)'
"$flutter_bin" build appbundle --release --target-platform android-arm64 --obfuscate --split-debug-info="$symbol_path"

python3 ../toolchain/verify_android_release.py build/app/outputs/bundle/release/app-release.aab
