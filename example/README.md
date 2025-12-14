# Wisp Example

WebGPUを使用したWispゲームエンジンのサンプルです。

## 必要条件

- Swift 6.2以上
- Swift SDK for WebAssembly

## セットアップ

### 1. Swift SDK for WASMをインストール

```bash
# swiftlyをインストール（まだの場合）
curl -L https://swiftlang.github.io/swiftly/swiftly-install.sh | bash

# Swift 6.2をインストール
swiftly install 6.2

# WASM SDKをインストール
swift sdk install https://download.swift.org/swift-6.2.3-release/wasm-sdk/swift-6.2.3-RELEASE/swift-6.2.3-RELEASE_wasm.artifactbundle.tar.gz
```

### 2. ビルド

```bash
cd example
chmod +x build.sh
./build.sh
```

または手動で:

```bash
swift package --swift-sdk wasm32-unknown-wasi js
```

### 3. 実行

```bash
npx serve .
```

ブラウザで `http://localhost:3000` を開きます。

## 操作方法

- **矢印キー / WASD**: 移動
- **Space**: アクション

## 必要なブラウザ

WebGPU対応ブラウザが必要です:
- Chrome 113+
- Edge 113+
- Safari 18+ (macOS Sequoia)
