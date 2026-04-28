# Flutter Builder

一个 Docker 镜像项目，用于编译 Flutter 项目并导出未 trim、携带符号表的 libapp.so。

## 功能特性

- 支持运行时指定 Flutter/Dart 版本
- 内置默认 Flutter 项目模板
- 编译生成包含完整符号表的 libapp.so
- 支持 debug/release 两种编译模式

## 环境变量

| 环境变量 | 必填 | 说明 | 示例 |
|----------|------|------|------|
| FLUTTER_VERSION | 是 | Flutter 版本号 | 3.24.0 |
| DART_VERSION | 是 | Dart 版本号 | 3.5.0 |
| BUILD_MODE | 否 | 编译模式，默认 debug | debug |
| PROJECT_PATH | 否 | 项目路径，默认 /workspace/flutter_demo | /workspace/my_project |

## 使用方法

### 基本用法

```bash
# 构建镜像
docker build -t flutter-builder ./flutter-builder

# 运行容器（使用默认项目）
docker run -it \
  -e FLUTTER_VERSION=3.24.0 \
  -e DART_VERSION=3.5.0 \
  -v ./output:/output \
  flutter-builder
```

### 使用自定义项目

```bash
# 准备你的 Flutter 项目
# 确保项目在当前目录的 ./my_project 文件夹下

docker run -it \
  -e FLUTTER_VERSION=3.24.0 \
  -e DART_VERSION=3.5.0 \
  -e PROJECT_PATH=/workspace/my_project \
  -e BUILD_MODE=debug \
  -v ./my_project:/workspace/my_project \
  -v ./output:/output \
  flutter-builder
```

### 输出产物

编译完成后，libapp.so 会保存在宿主机的 `./output` 目录下：

```
output/
└── libapp.so    # 包含完整符号表
```

## 验证符号表

```bash
# 查看符号数量
readelf -s output/libapp.so | grep -c "FUNC"

# 查看符号详情
readelf -s output/libapp.so | grep "FUNC" | head -20
```

## 支持的 Flutter 版本

所有从 Flutter 官方发布的 stable 版本都支持。常用版本：

- Flutter 3.24.0 / Dart 3.5.0
- Flutter 3.22.0 / Dart 3.4.0
- Flutter 3.19.0 / Dart 3.3.0
- Flutter 3.16.0 / Dart 3.2.0
- Flutter 3.13.0 / Dart 3.1.0

## 项目结构

```
flutter-builder/
├── Dockerfile                    # Docker 构建文件
├── docker-entrypoint.sh          # 容器入口脚本
├── scripts/
│   ├── install-flutter.sh        # Flutter 安装脚本
│   ├── build-project.sh          # 编译项目脚本
│   └── extract-so.sh             # SO 文件提取脚本
├── templates/
│   └── flutter_demo/             # 默认 Flutter 项目模板
│       ├── pubspec.yaml
│       ├── lib/main.dart
│       └── analysis_options.yaml
└── README.md                     # 使用说明
```

## 注意事项

1. 首次运行需要下载 Flutter SDK，时间可能较长
2. debug 模式编译速度较慢，但包含完整符号表
3. 建议分配至少 4GB 内存给 Docker
4. Android NDK 已预装在镜像中

## 故障排除

### 下载 Flutter 失败

检查网络连接，或尝试使用国内镜像（需要修改 install-flutter.sh）

### 编译失败

确保 Android SDK 组件已正确安装，可进入容器检查：

```bash
docker run -it --entrypoint /bin/bash flutter-builder
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --list
```

### libapp.so 为空或无符号

确认使用 debug 模式编译，release 模式默认会 strip 符号表