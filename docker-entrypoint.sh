#!/bin/bash
# ============================================
# Flutter Builder - 入口脚本
# ============================================
# 环境变量：
#   FLUTTER_VERSION (必填): Flutter 版本号，如 3.24.0
#   DART_VERSION (必填): Dart 版本号，如 3.5.0
#   BUILD_MODE (可选): debug 或 release，默认 debug
#   PROJECT_PATH (可选): 项目路径，默认 /workspace/flutter_demo

set -e

echo "============================================"
echo "Flutter Builder - 开始构建"
echo "============================================"

# 检查必填环境变量
if [ -z "$FLUTTER_VERSION" ]; then
    echo "错误: FLUTTER_VERSION 环境变量未设置"
    exit 1
fi

if [ -z "$DART_VERSION" ]; then
    echo "错误: DART_VERSION 环境变量未设置"
    exit 1
fi

# 设置默认值
BUILD_MODE=${BUILD_MODE:-debug}
PROJECT_PATH=${PROJECT_PATH:-/workspace/flutter_demo}

echo "Flutter 版本: $FLUTTER_VERSION"
echo "Dart 版本: $DART_VERSION"
echo "编译模式: $BUILD_MODE"
echo "项目路径: $PROJECT_PATH"
echo "============================================"

# 步骤 1: 安装 Flutter
echo "[1/5] 安装 Flutter $FLUTTER_VERSION..."
/workspace/scripts/install-flutter.sh
echo "[1/5] Flutter 安装完成"
FLUTTER_DIR=/opt/flutter
export PATH="$FLUTTER_DIR/bin:$PATH"
# 步骤 2: 进入项目目录
echo "[2/5] 准备项目..."
cd /workspace

# 检查项目目录是否存在
if [ -d "$PROJECT_PATH" ]; then
    cd "$PROJECT_PATH"
else
    echo "错误: 项目目录 $PROJECT_PATH 不存在"
    exit 1
fi

echo "当前目录: $(pwd)"

# 步骤 3: 获取依赖
echo "[3/5] 获取 Flutter 依赖..."
flutter pub get

# 步骤 4: 编译项目
echo "[4/5] 编译 Flutter 项目..."
/workspace/scripts/build-project.sh

# 步骤 5: 提取 libapp.so
echo "[5/5] 提取 libapp.so..."
/workspace/scripts/extract-so.sh

echo "============================================"
echo "构建完成!"
echo "输出文件: /output/libapp.so"
echo "============================================"

# 验证输出
if [ -f /output/libapp.so ]; then
    echo "libapp.so 文件大小: $(ls -lh /output/libapp.so | awk '{print $5}')"
    echo "验证符号表:"
    readelf -s /output/libapp.so | head -20
else
    echo "错误: libapp.so 未找到"
    exit 1
fi