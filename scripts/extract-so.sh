#!/bin/bash
# ============================================
# libflutter.so 提取脚本
# ============================================
# 从编译好的 APK 中提取 libflutter.so

set -e

OUTPUT_DIR=/output
SO_DIR=/output/so
FULL_DIR=/output/full
APK_DIR=/output/apk
TEMP_DIR=/tmp/apk_extract

echo "开始提取 libflutter.so..."

# 读取 APK 路径
if [ -f /tmp/apk_path.txt ]; then
    APK_PATH=$(cat /tmp/apk_path.txt)
else
    # 尝试查找 APK
    APK_PATH=$(find /workspace -name "*.apk" 2>/dev/null | head -1)
fi

if [ -z "$APK_PATH" ] || [ ! -f "$APK_PATH" ]; then
    echo "错误: 未找到 APK 文件"
    exit 1
fi

echo "APK 路径: $APK_PATH"

# 创建临时目录
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

# 创建输出目录
mkdir -p "$OUTPUT_DIR"
mkdir -p "$SO_DIR"
mkdir -p "$FULL_DIR"
mkdir -p "$APK_DIR"

# 解压 APK
echo "解压 APK..."
unzip -q "$APK_PATH" -d "$TEMP_DIR"

# 查找 libflutter.so
# Flutter 编译的 SO 文件可能在以下位置:
# - lib/arm64-v8a/libflutter.so (ARM64)
# - lib/armeabi-v7a/libflutter.so (ARM32)
# - lib/x86_64/libflutter.so (x86_64)
# - lib/x86/libflutter.so (x86)

LIBAPP_SO=""
for arch in arm64-v8a armeabi-v7a x86_64 x86; do
    SO_PATH="$TEMP_DIR/lib/$arch/libflutter.so"
    if [ -f "$SO_PATH" ]; then
        LIBAPP_SO=$SO_PATH
        echo "找到 libflutter.so ($arch)"
        break
    fi
done

if [ -z "$LIBAPP_SO" ]; then
    echo "错误: 未在 APK 中找到 libflutter.so"
    echo "APK 内容:"
    ls -la "$TEMP_DIR/lib/" 2>/dev/null || echo "lib 目录不存在"
fi

# 复制到输出目录
echo "复制 libflutter.so 到 so 目录..."
cp "$LIBAPP_SO" "$SO_DIR/libflutter.so"

# 复制 arm64 目录下的所有 so 文件到 so 目录
ARM64_DIR="$TEMP_DIR/lib/arm64-v8a"
if [ -d "$ARM64_DIR" ]; then
    echo "复制 arm64-v8a 目录下的所有 SO 文件..."
    cp -r "$ARM64_DIR"/* "$SO_DIR/" 2>/dev/null || true
fi

# 复制 APK 到 apk 目录
echo "复制 APK 到 apk 目录..."
cp "$APK_PATH" "$APK_DIR/app.apk"

# 复制编译输出目录到 full 目录
echo "复制编译输出目录到 full 目录..."
if [ -d "/workspace/flutter_demo/build" ]; then
    cp -r /workspace/flutter_demo/build "$FULL_DIR/build"
fi

# 验证符号表
echo ""
echo "验证 libflutter.so 符号表..."
SYMBOL_COUNT=$(readelf -s "$OUTPUT_DIR/libflutter.so" | grep -c "FUNC" || echo "0")
echo "符号表中 FUNC 符号数量: $SYMBOL_COUNT"

if [ "$SYMBOL_COUNT" -gt 0 ]; then
    echo "✓ libflutter.so 包含符号表"
    echo ""
    echo "前 20 个符号:"
    readelf -s "$OUTPUT_DIR/libflutter.so" | grep "FUNC" | head -20
else
    echo "警告: libflutter.so 可能不包含符号表"
fi

# 清理临时文件
echo ""
echo "清理临时文件..."
rm -rf "$TEMP_DIR"

echo ""
echo "提取完成!"
echo "============================================"
echo "输出文件:"
echo "  so 目录: $SO_DIR (包含 arm64-v8a 的 SO 文件)"
echo "  full 目录: $FULL_DIR (包含编译输出)"
echo "  apk 目录: $APK_DIR (包含 APK 文件)"
echo "============================================"