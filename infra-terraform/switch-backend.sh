#!/bin/bash

# ECS Native Blue-Green Deployment Script
export AWS_DEFAULT_REGION=ap-northeast-1

echo "=== ECS Native Blue-Green Deployment 開始 ==="

# 現在のタスク定義を確認
CURRENT_TASK_DEF=$(aws ecs describe-services --region ap-northeast-1 --cluster blue-green-app-backend-cluster --services blue-green-app-backend --query 'services[0].taskDefinition' --output text)
echo "現在のタスク定義: $CURRENT_TASK_DEF"

# 切り替え先のタスク定義を決定
if [[ $CURRENT_TASK_DEF == *"backend-blue"* ]]; then
    TARGET="green"
    TARGET_TASK_DEF="blue-green-app-backend-green"
else
    TARGET="blue"
    TARGET_TASK_DEF="blue-green-app-backend-blue"
fi

echo "デプロイ先: $TARGET ($TARGET_TASK_DEF)"

# ECS Native Blue-Green Deployment実行
echo "ECSネイティブブルーグリーンデプロイを実行中..."
aws ecs update-service \
    --region ap-northeast-1 \
    --cluster blue-green-app-backend-cluster \
    --service blue-green-app-backend \
    --task-definition $TARGET_TASK_DEF

# デプロイ完了まで待機
echo "デプロイ完了を待機中..."
aws ecs wait services-stable \
    --region ap-northeast-1 \
    --cluster blue-green-app-backend-cluster \
    --services blue-green-app-backend

echo "=== ECS Native Blue-Green Deployment 完了: $TARGET ==="