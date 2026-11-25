#!/usr/bin/env bash
# Builds the bridge for Android arm64, all on this machine, without `dart
# build`, which doesn't target Android yet (dart-lang/sdk#62327), and whose
# `dart compile` refuses packages with build hooks, such as usb_gadget.
#
#   1. usb_gadget's Rust library, with cargo and the Android NDK: what its
#      build hook would build. It goes to bridge/assets/, and build_runner
#      embeds it in the bridge (package:embed), which writes it out on
#      startup.
#   2. A native-assets mapping from usb_gadget's code asset ID to where the
#      bridge writes the library: what `dart build` would write.
#   3. The bridge as an AOT kernel for Android, with that mapping.
#   4. The AOT snapshot, with the host gen_snapshot of a Dart SDK built for
#      Android (`tools/build.py --mode=release --arch=arm64 --os=android
#      create_sdk`, same version as this one).
#   5. One executable, as `dart compile exe` writes it: that build's Android
#      dartaotruntime with the snapshot appended.
#
# Usage:
#   tool/build_bridge.sh [--out <dir>] [--asset]
#
#   --asset    also copy the executable to droidshock3/assets/bridge, which
#              the app installs
#
# Output (default build/bridge/): bridge, and its intermediates.
#
# Environment:
#   DART_ANDROID_BUILD  the Android SDK build's output directory (default
#                       ~/Temp/dart-sdk-src/sdk/xcodebuild/ReleaseAndroidARM64)
#   ANDROID_NDK_HOME    the NDK (default: the newest in the Android SDK)
#   FFSDS3_LOG          the bridge's device logs, true or false (default true)
#   FFSDS3_LOG_LEVEL    the lowest level logged: 0 debug, 1 info, 2 success,
#                       3 warning, 4 error, 5 fatal (default 1, info)
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
out="$root/build/bridge"
asset=false
while (($#)); do
  case "$1" in
    --out) out=${2:?--out needs a value}; shift 2 ;;
    --asset) asset=true; shift ;;
    -h | --help) sed -n '/^# Usage:/,/^set -e/p' "$0" | sed '$d; s/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

step() { printf '\n== %s\n' "$*"; }
fail() { echo "$*" >&2; exit 1; }

# Where the bridge writes the library on the device: kNativeLibraryPath in
# bridge/bin/bridge.dart, under protocol's kBridgeDir.
bridge_dir=$(sed -n "s/^const kBridgeDir = '\(.*\)';/\1/p" "$root/protocol/lib/src/protocol.dart")
lib_name=$(sed -n "s/^const kNativeLibraryPath = '\$kBridgeDir\/\(.*\)';/\1/p" "$root/bridge/bin/bridge.dart")
[[ -n $bridge_dir && -n $lib_name ]] || fail "kBridgeDir or kNativeLibraryPath not found"
asset_id=package:usb_gadget/src/rust/frb_generated.io.dart
rust_target=aarch64-linux-android
api=24 # Flutter's minimum, as the NDK compiler prefix.

dart_bin=$(command -v dart) || fail "dart not found"
sdk=$(cd "$(dirname "$(readlink -f "$dart_bin")")/.." && pwd)
[[ -x $sdk/bin/dartaotruntime ]] || sdk="$sdk/bin/cache/dart-sdk" # Flutter's dart wrapper.
[[ -x $sdk/bin/dartaotruntime ]] || fail "Dart SDK not found from $dart_bin"
sdk_version=$(cat "$sdk/version")

android=${DART_ANDROID_BUILD:-$HOME/Temp/dart-sdk-src/sdk/xcodebuild/ReleaseAndroidARM64}
gen_snapshot="$android/clang_arm64/gen_snapshot_product"
runtime="$android/dart-sdk/bin/dartaotruntime"
[[ -x $gen_snapshot && -f $runtime ]] || fail "No Dart SDK build for Android in $android"
android_version=$(cat "$android/dart-sdk/version")
[[ $android_version == "$sdk_version" ]] ||
  fail "The Android build is Dart $android_version, this SDK $sdk_version: rebuild it at $sdk_version."

ndk=${ANDROID_NDK_HOME:-$(ls -d "$HOME/Library/Android/sdk/ndk/"* 2> /dev/null | sort -V | tail -1)}
[[ -d $ndk ]] || fail "Android NDK not found: set ANDROID_NDK_HOME"
ndk_bin=$(ls -d "$ndk"/toolchains/llvm/prebuilt/*/bin | head -1)

mkdir -p "$out"
cd "$root"

step "Packages (Dart $sdk_version)"
dart pub get > /dev/null
usb_gadget=$(python3 -c '
import json, sys
from urllib.parse import urlparse, unquote
for p in json.load(open(sys.argv[1]))["packages"]:
    if p["name"] == "usb_gadget":
        print(unquote(urlparse(p["rootUri"]).path))
' "$root/.dart_tool/package_config.json")
[[ -d $usb_gadget/rust ]] || fail "usb_gadget's Rust crate not found"
echo "usb_gadget: $usb_gadget"

step "1. $lib_name for $rust_target, embedded in the bridge"
linker="$ndk_bin/$rust_target$api-clang"
cargo_target=$(tr '[:lower:]-' '[:upper:]_' <<< "$rust_target")
(
  cd "$usb_gadget/rust"
  env \
    "CC_${rust_target//-/_}=$linker" \
    "AR_${rust_target//-/_}=$ndk_bin/llvm-ar" \
    "CARGO_TARGET_${cargo_target}_LINKER=$linker" \
    "CARGO_TARGET_${cargo_target}_RUSTFLAGS=-C link-arg=-Wl,-z,max-page-size=16384" \
    cargo build --release --target "$rust_target" --target-dir "$root/build/cargo" --quiet
)
mkdir -p "$root/bridge/assets"
"$ndk_bin/llvm-strip" -o "$root/bridge/assets/$lib_name" \
  "$root/build/cargo/$rust_target/release/$lib_name"
(cd "$root/bridge" && dart run build_runner build --delete-conflicting-outputs > /dev/null)

step "2. native_assets.json: $asset_id -> $bridge_dir/$lib_name"
cat > "$out/native_assets.json" << EOF
{
  "format-version": [1, 0, 0],
  "native-assets": {
    "android_arm64": {
      "$asset_id": ["absolute", "$bridge_dir/$lib_name"]
    }
  }
}
EOF

step "3. bridge.dill"
"$sdk/bin/dartaotruntime" "$sdk/bin/snapshots/gen_kernel_aot.dart.snapshot" \
  --platform "$sdk/lib/_internal/vm_platform_product.dill" \
  --aot -Ddart.vm.product=true --target-os android \
  -DFFSDS3_LOG="${FFSDS3_LOG:-true}" -DFFSDS3_LOG_LEVEL="${FFSDS3_LOG_LEVEL:-1}" \
  --native-assets "$out/native_assets.json" \
  --packages "$root/.dart_tool/package_config.json" \
  -o "$out/bridge.dill" "$root/bridge/bin/bridge.dart"

step "4. bridge.aot"
"$gen_snapshot" --snapshot-kind=app-aot-elf --elf="$out/bridge.aot" "$out/bridge.dill"

step "5. bridge"
# As dart2native's writeAppendedExecutable: the runtime padded to 64 KiB,
# the snapshot, its offset (u64 little endian), then appJitMagicNumber.
python3 -c '
import struct, sys
runtime, snapshot = (open(p, "rb").read() for p in sys.argv[1:3])
offset = -(-len(runtime) // 65536) * 65536
open(sys.argv[3], "wb").write(runtime + bytes(offset - len(runtime)) + snapshot
    + struct.pack("<Q", offset) + bytes([0xdc, 0xdc, 0xf6, 0xf6, 0, 0, 0, 0]))
' "$runtime" "$out/bridge.aot" "$out/bridge"
chmod +x "$out/bridge"
ls -lh "$out/bridge"

if $asset; then
  cp "$out/bridge" "$root/droidshock3/assets/bridge"
  echo "Copied to droidshock3/assets/bridge"
fi
