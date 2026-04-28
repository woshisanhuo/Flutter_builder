# ============================================
# Flutter Builder Docker Image
# ============================================
# 基于 Ubuntu 20.04，提供可配置版本的 Flutter 编译环境
# 输出未 trim、携带符号表的 libapp.so

FROM ubuntu:20.04 AS base

# 避免交互式提示
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# 安装基础依赖
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    openjdk-17-jdk \
    wget \
    && rm -rf /var/lib/apt/lists/*

# ============================================
# Android SDK 安装阶段
# ============================================
FROM base AS android-sdk

ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH=${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools

# 创建 Android SDK 目录
RUN mkdir -p ${ANDROID_HOME}

# 下载并安装 Android SDK command-line tools
WORKDIR ${ANDROID_HOME}
RUN wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O cmdline-tools.zip && \
    unzip -q cmdline-tools.zip && \
    mkdir -p cmdline-tools/latest && \
    mv cmdline-tools/* cmdline-tools/latest/ 2>/dev/null || true && \
    rm cmdline-tools.zip

# 接受许可证
RUN yes | ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager --licenses > /dev/null 2>&1 || true

# 安装必要的 SDK 组件
RUN ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager --install \
    "platform-tools" \
    "platforms;android-34" \
    "build-tools;34.0.0" \
    "ndk;25.2.9519653" \
    "cmake;3.22.1"

# ============================================
# Flutter 构建阶段
# ============================================
FROM android-sdk AS builder

# 设置工作目录
WORKDIR /workspace

# 复制脚本文件
COPY scripts/ /workspace/scripts/
RUN chmod +x /workspace/scripts/*.sh

# 复制默认 Flutter 项目模板
COPY templates/flutter_demo/ /workspace/flutter_demo/

# 创建输出目录
RUN mkdir -p /output

# 复制入口脚本
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# 设置入口点
ENTRYPOINT ["/docker-entrypoint.sh"]