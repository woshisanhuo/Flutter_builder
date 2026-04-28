#!/bin/bash
# ============================================
# Flutter 项目编译脚本
# ============================================
# 环境变量：
#   BUILD_MODE: debug 或 release，默认 debug

set -e

BUILD_MODE=${BUILD_MODE:-debug}

echo "开始编译 Flutter 项目..."
echo "编译模式: $BUILD_MODE"

# 确保 Flutter 在 PATH 中
export PATH="/opt/flutter/bin:$PATH"

# 检查 Flutter 是否可用
if ! command -v flutter &> /dev/null; then
    echo "错误: Flutter 命令不可用"
    exit 1
fi

# 显示 Flutter 版本
echo "Flutter 版本:"
flutter --version
echo ""

# 获取当前目录
PROJECT_DIR=$(pwd)
echo "项目目录: $PROJECT_DIR"

# 检查是否是 Flutter 项目
if [ ! -f "pubspec.yaml" ]; then
    echo "错误: 当前目录不是 Flutter 项目（缺少 pubspec.yaml）"
    exit 1
fi

# 确保已获取依赖
echo "确保依赖已获取..."
flutter pub get
echo ""

# 根据模式编译
if [ "$BUILD_MODE" = "release" ]; then
    echo "执行 Release 编译..."
    # Release 模式需要额外配置以保留符号表
    # Flutter release 默认会 strip 符号，我们使用 debuggable 编译保留符号
    flutter build apk --release --no-tree-shake-icons --dart-define=android.strip=false
else
    echo "执行 Debug 编译（保留符号表）..."
    # Debug 模式默认保留符号表
    flutter build apk --debug --no-tree-shake-icons --dart-define=android.strip=false
fi

# 查找生成的 APK
APK_PATH=$(find build/app/outputs/flutter-apk -name "*.apk" 2>/dev/null | head -1)

if [ -z "$APK_PATH" ]; then
    # 尝试其他可能的位置
    APK_PATH=$(find . -name "*.apk" 2>/dev/null | head -1)
fi

if [ -z "$APK_PATH" ]; then
    echo "错误: 未找到生成的 APK 文件"
    exit 1
fi

echo "APK 生成成功: $APK_PATH"
echo "APK 大小: $(ls -lh "$APK_PATH" | awk '{print $5}')"

# 将 APK 路径写入临时文件，供 extract-so.sh 使用
echo "$APK_PATH" > /tmp/apk_path.txt

echo "编译完成!"