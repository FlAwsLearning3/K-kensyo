<!--
=============================================================================
ECSネイティブブルーグリーンデプロイメント ドキュメント

このファイルでは以下の内容を説明しています：
- アーキテクチャの概要と特徴
- インフラストラクチャのデプロイ手順
- ブルーグリーンデプロイの実行方法
- Service Connectの利点と使用方法
- トラブルシューティングガイド
- 監視とログの確認方法
- ロールバック手順

CodeDeployを使用せず、ECSネイティブ機能とAWS CLIでブルーグリーンデプロイを実現
=============================================================================
-->

# ECS Native Blue-Green Deployment with Service Connect

このプロジェクトは、CodeDeployを使用せずにECSネイティブのブルーグリーンデプロイメントをService Connect経由で実行するためのTerraform設定です。

## アーキテクチャ

- **ECS Cluster**: Service Connectが有効
- **Service Discovery**: HTTP名前空間でService Connectを設定
- **ALB**: BlueとGreenの2つのターゲットグループ
- **ECS Service**: Service Connect設定でapp:8080エンドポイントを提供
- **ブルーグリーンデプロイ**: ECSネイティブ機能を使用

## デプロイ手順

### 1. GitHub設定

1. **Personal Access Token作成**:
   - GitHub Settings → Developer settings → Personal access tokens
   - `repo` スコープを選択してトークンを生成

2. **terraform.tfvarsを設定**:
   ```hcl
   github_owner = "your-github-username"
   github_repo  = "K-kensyo"
   github_token = "your-github-token"
   ```

### 2. インフラストラクチャのデプロイ

```bash
cd infra-terraform
terraform init
terraform plan
terraform apply
```

### 3. 自動デプロイ

- GitHubにコードをプッシュすると自動的にパイプラインが実行
- **パイプラインの流れ**:
  1. **Source**: GitHubからソースコード取得
  2. **Build**: Dockerイメージをビルド・ECRにプッシュ
  3. **Deploy**: ECSネイティブブルーグリーンデプロイを実行

## Service Connect の利点

1. **サービス間通信**: `app:8080` でアプリケーションにアクセス可能
2. **ロードバランシング**: Service Connectが自動的にロードバランシング
3. **サービスディスカバリー**: DNS名前解決が自動化
4. **ヘルスチェック**: 自動的なヘルスチェックとフェイルオーバー

## ブルーグリーンデプロイの流れ

1. 新しいタスク定義を作成
2. ECSサービスを新しいタスク定義で更新
3. 新しいタスクをスタンバイターゲットグループに登録
4. ヘルスチェックが通るまで待機
5. ALBリスナーをスタンバイターゲットグループに切り替え
6. 古いターゲットグループからタスクを削除

## 設定オプション

### terraform.tfvars

```hcl
enable_client = true     # Service Connectテスト用クライアントを有効化
github_owner  = "user"   # GitHubユーザー名
github_repo   = "repo"   # GitHubリポジトリ名
github_token  = "***"    # GitHub Personal Access Token
```

### Service Connectクライアントのテスト

クライアントサービスを有効にすると、Service Connect経由でアプリケーションにアクセスするテストコンテナが起動します：

```bash
# クライアントサービスのログを確認
aws logs tail /ecs/blue-green-app-client --follow
```

## トラブルシューティング

### ヘルスチェックが失敗する場合

1. セキュリティグループの設定を確認
2. アプリケーションのヘルスチェックエンドポイントを確認
3. ターゲットグループのヘルスチェック設定を調整

### Service Connectが動作しない場合

1. ECSクラスターでService Connectが有効になっているか確認
2. 名前空間の設定を確認
3. タスク定義のportMappingsにnameが設定されているか確認

## 監視とログ

- **CloudWatch Logs**: `/ecs/blue-green-app` でアプリケーションログを確認
- **ECS Console**: サービスの状態とタスクの健全性を監視
- **ALB Console**: ターゲットグループの健全性を確認

## ロールバック

問題が発生した場合は、以下の方法でロールバック可能：

1. **即座のロールバック**（ALBリスナー切り替え）:
   ```bash
   aws elbv2 modify-listener \
     --listener-arn <listener-arn> \
     --default-actions Type=forward,TargetGroupArn=<previous-target-group-arn>
   ```

2. **CodePipelineでのロールバック**:
   - 前のコミットに戻してプッシュ
   - パイプラインが自動的に前のバージョンをデプロイ