#!/bin/bash
# ============================================
# Flutter SDK 安装脚本
# ============================================
# 环境变量：
#   FLUTTER_VERSION: Flutter 版本号
#   DART_VERSION: Dart 版本号

set -e

FLUTTER_VERSION=${FLUTTER_VERSION:-3.24.0}
DART_VERSION=${DART_VERSION:-3.5.0}

FLUTTER_DIR=/opt/flutter

echo "开始安装 Flutter $FLUTTER_VERSION..."

# 检查是否已安装
if [ -d "$FLUTTER_DIR" ]; then
    echo "Flutter 已安装在 $FLUTTER_DIR"
    # 检查版本
    if [ -f "$FLUTTER_DIR/bin/flutter" ]; then
        CURRENT_VERSION=$("$FLUTTER_DIR/bin/flutter" --version 2>/dev/null | head -1 || echo "")
        if [[ "$CURRENT_VERSION" == *"Flutter $FLUTTER_VERSION"* ]]; then
            echo "Flutter $FLUTTER_VERSION 已安装，跳过"
            exit 0
        else
            echo "版本不匹配，删除旧版本重新安装"
            rm -rf "$FLUTTER_DIR"
        fi
    fi
fi

# 构建下载 URL
# Flutter 版本格式: 3.24.0 -> flutter_linux_3.24.0-stable.tar.xz
FLUTTER_TAR_NAME="flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/${FLUTTER_TAR_NAME}"

echo "下载 URL: $FLUTTER_URL"

# 下载 Flutter SDK（带重试）
MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    echo "下载尝试 $((RETRY_COUNT + 1))/$MAX_RETRIES..."
    
    if wget -q --show-progress -O /tmp/flutter.tar.xz "$FLUTTER_URL"; then
        echo "下载完成"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            echo "下载失败，5秒后重试..."
            sleep 5
        else
            echo "下载失败，已达到最大重试次数"
            exit 1
        fi
    fi
done

# 解压 Flutter SDK
echo "解压 Flutter SDK..."
mkdir -p /opt
tar -xf /tmp/flutter.tar.xz -C /opt
rm -f /tmp/flutter.tar.xz

# 添加到 PATH
export PATH="$FLUTTER_DIR/bin:$PATH"

# 配置 Flutter
echo "配置 Flutter..."
git config --global --add safe.directory /opt/flutter
flutter config --no-analytics
flutter precache

ln -s /opt/flutter/bin/flutter /usr/local/bin/flutter
ln -s /opt/flutter/bin/dart /usr/local/bin/dart
# 验证安装
echo "验证 Flutter 安装..."
flutter --version

# 检查 Dart 版本
DART_INSTALLED_VERSION=$(flutter --version 2>/dev/null | grep -oP 'Dart \K[0-9.]+' || echo "")
echo "安装的 Dart 版本: $DART_INSTALLED_VERSION"

if [ -n "$DART_VERSION" ] && [ "$DART_INSTALLED_VERSION" != "$DART_VERSION" ]; then
    echo "警告: 请求的 Dart 版本是 $DART_VERSION，但安装的是 $DART_INSTALLED_VERSION"
    echo "Flutter SDK 捆绑特定版本的 Dart，如需不同版本请使用对应版本的 Flutter"
fi

echo "Flutter 安装完成!"