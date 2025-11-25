# =============================================================================
# Terraform変数定義ファイル
# 
# このファイルでは以下の変数を定義しています：
# - AWSリージョン、環境名、アプリケーション名
# - コンテナイメージ、ポート、タスク数の設定
# - CPU、メモリのリソース設定
# - ブルーグリーンデプロイ、クライアントサービスの有効/無効設定
# - ターミネーション待機時間の設定
# 
# 各変数にはデフォルト値が設定されており、terraform.tfvarsで上書き可能
# =============================================================================

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "blue-green-app"
}

variable "container_image" {
  description = "Container image URI"
  type        = string
  default     = "nginx:latest"
}

variable "container_port" {
  description = "Container port"
  type        = number
  default     = 8080
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 2
}

variable "cpu" {
  description = "Task CPU"
  type        = string
  default     = "256"
}

variable "memory" {
  description = "Task memory"
  type        = string
  default     = "512"
}



variable "enable_client" {
  description = "Enable Service Connect client service for testing"
  type        = bool
  default     = false
}

variable "enable_pipeline" {
  description = "Enable CodePipeline for CI/CD"
  type        = bool
  default     = true
}

variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
  default     = ""
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = ""
}

variable "github_branch" {
  description = "GitHub branch name"
  type        = string
  default     = "main"
}

variable "github_token" {
  description = "GitHub personal access token"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ecr_repository_name" {
  description = "ECR repository name"
  type        = string
  default     = "blue-green-app"
}