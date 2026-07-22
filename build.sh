#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"

# 1) 生成 Xcode 工程（仅当尚不存在时）
if [ ! -d RandomLauncher.xcodeproj ]; then
  xcodegen generate
fi

# 2) 编译（关闭签名，后续用 ldid 伪造签名供 TrollStore 使用）
xcodebuild -target RandomLauncher \
  -configuration Release \
  -sdk iphoneos \
  -arch arm64 \
  CODE_SIGNING_ALLOWED=NO \
  ENABLE_BITCODE=NO \
  build

# 3) 定位生成的 .app
APP=$(find build -name "RandomLauncher.app" -type d | head -n1)
if [ -z "$APP" ]; then
  echo "未找到编译产物 RandomLauncher.app" >&2
  exit 1
fi
echo "App 产物: $APP"

# 4) 安装/确保 ldid 可用
if ! command -v ldid >/dev/null 2>&1; then
  brew install ldid
fi

# 5) 用私有权限伪造签名
ldid -S App.entitlements "$APP"

# 6) 打包为 IPA（Payload/ 结构）
rm -rf Payload RandomLauncher.ipa
mkdir Payload
cp -r "$APP" Payload/
zip -r RandomLauncher.ipa Payload >/dev/null

echo "完成：$(pwd)/RandomLauncher.ipa"
