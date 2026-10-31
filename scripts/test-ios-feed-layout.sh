#!/bin/bash
# 编译生产尺寸观察器，在真实 iOS 模拟器 UIKit 中执行，不依赖 Ads-CN 或应用工程。
set -euo pipefail
SDK_ROOT=$(cd "$(dirname "$0")/.." && pwd)
TEST_BUILD=$(mktemp -d "${TMPDIR:-/tmp}/brayant-ios-feed.XXXXXX")
APP="$TEST_BUILD/FeedLayoutRegression.app"
BUNDLE_ID=com.brayantad.feed-layout-regression
mkdir -p "$APP"
SIMULATOR_ID=${SIMULATOR_ID:-$(xcrun simctl list devices available -j | python3 -c '
import json,sys
items=[d for runtime,devices in json.load(sys.stdin)["devices"].items() if runtime.endswith("iOS-18-6") for d in devices if d.get("isAvailable")]
items.sort(key=lambda d:(d["state"]!="Booted", "iPhone" not in d["name"]))
if not items: sys.exit("未找到可用 iOS 18.6 模拟器，请通过 SIMULATOR_ID 指定设备")
print(items[0]["udid"])
')}
SDK_PATH=$(xcrun --sdk iphonesimulator --show-sdk-path)
ARCH=$(uname -m)
xcrun --sdk iphonesimulator clang -fobjc-arc -fmodules \
  -target "$ARCH-apple-ios15.0-simulator" -isysroot "$SDK_PATH" \
  -framework UIKit -framework QuartzCore \
  -I "$SDK_ROOT/ios/PangleAdModule" \
  "$SDK_ROOT/ios/PangleAdModule/BrayantAdSizeObserver.m" \
  "$SDK_ROOT/tests/ios/FeedLayoutRegression.m" \
  -o "$APP/FeedLayoutRegression"
cat > "$APP/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>com.brayantad.feed-layout-regression</string>
<key>CFBundleExecutable</key><string>FeedLayoutRegression</string>
<key>CFBundleName</key><string>FeedLayoutRegression</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>MinimumOSVersion</key><string>15.0</string>
<key>LSRequiresIPhoneOS</key><true/>
<key>UIDeviceFamily</key><array><integer>1</integer><integer>2</integer></array>
<key>UILaunchScreen</key><dict/>
</dict></plist>
PLIST
codesign --force --sign - "$APP"
STATE=$(xcrun simctl list devices available -j | python3 -c 'import json,sys; print(next(d["state"] for ds in json.load(sys.stdin)["devices"].values() for d in ds if d["udid"]==sys.argv[1]))' "$SIMULATOR_ID")
STARTED_SIMULATOR=0
cleanup() {
  local test_status=$?
  trap - EXIT
  # 只清理本测试应用，并恢复由脚本启动的设备；保留编译产物与日志。
  xcrun simctl uninstall "$SIMULATOR_ID" "$BUNDLE_ID" >/dev/null 2>&1 || true
  if [ "$STARTED_SIMULATOR" = 1 ]; then
    xcrun simctl shutdown "$SIMULATOR_ID" >/dev/null 2>&1 || true
  fi
  exit "$test_status"
}
trap cleanup EXIT
if [ "$STATE" != Booted ]; then
  xcrun simctl boot "$SIMULATOR_ID"
  STARTED_SIMULATOR=1
fi
xcrun simctl bootstatus "$SIMULATOR_ID" -b
xcrun simctl install "$SIMULATOR_ID" "$APP"
# --console 随测试进程退出；检查成功标记同时防止异常退出被 simctl 误判为通过。
xcrun simctl launch --terminate-running-process --console "$SIMULATOR_ID" "$BUNDLE_ID" 2>&1 | tee "$TEST_BUILD/result.log"
if ! grep -q 'BRAYANT_IOS_LAYOUT_PASS' "$TEST_BUILD/result.log"; then
  echo "iOS 回归未通过，日志：$TEST_BUILD/result.log" >&2
  exit 1
fi
echo "iOS 回归通过，日志：$TEST_BUILD/result.log"
