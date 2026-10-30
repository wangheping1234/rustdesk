#!/usr/bin/env bash
set -eo pipefail

cargo install flutter_rust_bridge_codegen --version 1.80.1 --features uuid --locked

flutter packages pub get --enforce-lockfile

# basilgello: Unfortunately, this protection is not enough to prevent hijack
# because `flutter build` calls another `dart pub get` under the hood and we
# can not pass `--enforce-lockfile` to `flutter build` to make it enforce the
# lockfile.
#
# We can not pass `--no-pub` to `flutter build` either because it also disables
# generation of flutter headers and causes weird CMake errors like
# `missing flutter_generated.cmake`.
#
# However, we can abuse the fact that `flutter build` skips unprotected `pub get`
# entirely if package lockfile (`.dart_tool/package_config.json`) was created by
# the generator other than `pub`.
#
# So we patch that file so `flutter build` skips unprotected package re-resolution.
if [ -f '.dart_tool/package_config.json' ]; then
  sed -i -e 's/"pub"/"pubForced"/' '.dart_tool/package_config.json'
  echo 'Successfully updated "generator" to "pubForced" in ".dart_tool/package_config.json"'
fi

~/.cargo/bin/flutter_rust_bridge_codegen --rust-input ../src/flutter_ffi.rs --dart-output ./lib/generated_bridge.dart --c-output ./macos/Runner/bridge_generated.h
# call `flutter clean` if cargo build fails
# export LLVM_HOME=/Library/Developer/CommandLineTools/usr/
cargo build --locked --features flutter

flutter run "$@"
