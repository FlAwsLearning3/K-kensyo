# =============================================================================
# Terraform変数値設定ファイル
# 
# このファイルでは以下の設定を行います：
# - AWSリージョン: ap-northeast-1 (東京リージョン)
# - 環境: dev (開発環境)
# - アプリケーション名: blue-green-app
# - コンテナイメージ: nginx:latest (テスト用)
# - コンテナポート: 8080
# - タスク数: 2 (高可用性のため)
# - CPU/メモリ: 256/512 (Fargate最小構成)
# - ブルーグリーンデプロイ: 有効
# - クライアントサービス: 無効 (必要に応じて有効化)
# =============================================================================

region                = "ap-northeast-1"
environment           = "dev"
app_name              = "blue-green-app"
container_image       = "nginx:latest"
container_port        = 8080
desired_count         = 2
cpu                   = "256"
memory                = "512"
enable_client         = false
enable_pipeline       = true
github_owner          = "FlAwsLearning3"
github_repo           = "K-kensyo"
github_branch         = "main"
github_token          = "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"  # 実際のGitHubトークンに置き換えてください
ecr_repository_name   = "blue-green-app"