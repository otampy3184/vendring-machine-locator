# VendingMachine Locator (自販機まっぷ)

VendingMachine Locatorは、自動販売機の位置情報を共有・管理するためのiOSアプリケーションです。ユーザーは地図上で近くの自動販売機を検索したり、新しい自動販売機の位置を登録したりできます。

## 機能概要

### 主要機能
- **インタラクティブマップ**: 自動販売機の位置をピンで表示
- **リアルタイム位置情報**: 現在地からの距離計算と最寄りの自動販売機検索
- **自動販売機登録**: 認証済みユーザーによる新規位置登録
- **詳細情報管理**: 機種、稼働状況、支払い方法の記録
- **画像位置情報抽出**: 写真のExifデータから自動的に位置情報を取得
- **フィルタリング**: 機種別表示切り替え
- **削除機能**: 登録した自動販売機の削除

### 特徴的な機能
- **AI画像認識**: Vision Frameworkによる自動販売機の自動検出（開発中）
- **登録成功演出**: クラッカーアニメーションによる視覚的フィードバック
- **オフライン対応**: 一部機能のオフライン利用

## 技術スタック

### アーキテクチャ
- **設計パターン**: MVVM (Model-View-ViewModel)
- **UIフレームワーク**: SwiftUI
- **リアクティブプログラミング**: Combine
- **最小iOS要件**: iOS 17.0以上

### 主要技術
- **言語**: Swift 5.9
- **開発環境**: Xcode 15.0+
- **バックエンド**: Firebase (Firestore, Storage, Authentication)
- **位置情報**: Core Location
- **地図**: MapKit
- **画像処理**: PhotosUI, Core Image
- **AI/ML**: Vision Framework

### 依存関係
- Firebase iOS SDK
- Core Location
- MapKit
- PhotosUI
- Vision Framework

## プロジェクト構造

```
VendingMachineLocator/
├── Models/              # データモデル
│   ├── VendingMachine.swift
│   └── LocationManager.swift
├── ViewModels/          # ビューモデル
│   ├── MapViewModel.swift
│   └── AddMachineViewModel.swift
├── Views/               # SwiftUIビュー
│   ├── MapView.swift
│   ├── AddVendingMachineView.swift
│   └── Components/
├── Services/            # サービス層
│   ├── FirestoreService.swift
│   ├── AuthService.swift
│   └── StorageService.swift
├── Utilities/           # ユーティリティ
│   ├── ExifLocationExtractor.swift
│   └── Extensions/
└── Resources/           # リソースファイル
    ├── GoogleService-Info.plist
    └── Assets.xcassets
```

## セットアップ手順

### 1. 前提条件
- macOS 13.0以上
- Xcode 15.0以上
- Cocoapods または Swift Package Manager
- Firebaseプロジェクト

### 2. インストール
```bash
# リポジトリのクローン
git clone https://github.com/yourusername/VendingMachineLocator.git
cd VendingMachineLocator

# 依存関係のインストール (SPM使用の場合)
# Xcodeで自動的に解決されます

# Firebaseの設定
# GoogleService-Info.plistをプロジェクトに追加
```

### 3. Firebase設定
1. [Firebase Console](https://console.firebase.google.com)でプロジェクトを作成
2. iOSアプリを追加（Bundle ID: `com.yourcompany.VendingMachineLocator`）
3. `GoogleService-Info.plist`をダウンロードしてプロジェクトに追加
4. Firestore Databaseを有効化
5. Firebase Authenticationを有効化（匿名認証）
6. Firebase Storageを有効化

### 4. ビルドと実行
1. Xcodeでプロジェクトを開く
2. 開発チームとBundle Identifierを設定
3. シミュレーターまたは実機でビルド

## 使用方法

### 基本的な使い方
1. **アプリ起動**: 地図画面が表示され、現在地周辺の自動販売機が表示されます
2. **自動販売機の検索**: 地図を移動・ズームして目的の場所を探します
3. **詳細表示**: ピンをタップして自動販売機の詳細情報を確認
4. **新規登録**: ＋ボタンから新しい自動販売機を登録

### 自動販売機の登録
1. 画面右下の＋ボタンをタップ
2. 以下の情報を入力：
   - 説明（必須）
   - 機種（飲料、食品、アイス、その他）
   - 稼働状況
   - 支払い方法
3. 位置情報の設定：
   - 現在地を使用
   - 地図から選択
   - 写真から自動取得
4. 登録ボタンをタップ

### フィルタリング
- 画面上部のフィルターボタンから機種別表示を切り替え
- 「すべて」「飲料」「食品」「アイス」「その他」から選択

## データモデル

### VendingMachine
```swift
struct VendingMachine {
    let id: String
    let latitude: Double
    let longitude: Double
    let description: String
    let machineType: MachineType
    let isOperational: Bool
    let paymentMethods: [PaymentMethod]
    let createdAt: Date
    let userId: String
    let imageURL: String?
}
```

### 機種分類
- **飲料**: 一般的な飲料自動販売機
- **食品**: 軽食・お菓子の自動販売機
- **アイス**: アイスクリーム専用機
- **その他**: 特殊な商品の自動販売機

## セキュリティ

### 認証
- Firebase Authenticationによる匿名認証
- ユーザーIDベースのアクセス制御

### データ保護
- Firestore Security Rulesによるアクセス制限
- 自分が登録したデータのみ編集・削除可能

### プライバシー
- 位置情報の使用は明示的な許可が必要
- 個人情報の収集は最小限

## パフォーマンス最適化

### 地図表示
- クラスタリングによる大量ピンの効率的表示
- 視野範囲内のデータのみ読み込み

### 画像処理
- 画像の自動圧縮とサムネイル生成
- Firebase Storageへの効率的アップロード

### キャッシング
- 頻繁にアクセスするデータのメモリキャッシュ
- オフライン時のローカルキャッシュ

## 開発者向け情報

### ビルド設定
- Development Team: 要設定
- Bundle Identifier: `com.yourcompany.VendingMachineLocator`
- Deployment Target: iOS 17.0

### テスト
```bash
# ユニットテストの実行
xcodebuild test -scheme VendingMachineLocator

# UIテストの実行
xcodebuild test -scheme VendingMachineLocatorUITests
```

### デバッグ
- Firebase DebugViewの活用
- Xcode Instrumentsでのパフォーマンス分析

### コーディング規約
- Swift API Design Guidelinesに準拠
- SwiftLintによる自動フォーマット
- 意味のある変数名とコメント
