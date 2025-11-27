#!/bin/bash

# Blue-Green Backend切り替えスクリプト
export AWS_DEFAULT_REGION=ap-northeast-1

echo "=== Blue-Green Backend切り替え開始 ==="

# 現在のアクティブ環境を確認
CURRENT=$(aws ssm get-parameter --name "/blue-green-app/active-backend" --region ap-northeast-1 --query "Parameter.Value" --output text)
echo "現在のアクティブ環境: $CURRENT"

# 切り替え先を決定
if [ "$CURRENT" = "blue" ]; then
    TARGET="green"
    TARGET_SERVICE="blue-green-app-backend-green"
    OLD_SERVICE="blue-green-app-backend-blue"
else
    TARGET="blue"
    TARGET_SERVICE="blue-green-app-backend-blue"
    OLD_SERVICE="blue-green-app-backend-green"
fi

echo "デプロイ先: $TARGET"

# 新環境を起動
echo "新環境 ($TARGET) を起動中..."
aws ecs update-service \
    --region ap-northeast-1 \
    --cluster blue-green-app-backend-cluster \
    --service $TARGET_SERVICE \
    --desired-count 1

# サービスが安定するまで待機
echo "サービスの安定化を待機中..."
aws ecs wait services-stable \
    --region ap-northeast-1 \
    --cluster blue-green-app-backend-cluster \
    --services $TARGET_SERVICE

# Service Connectの切り替え
echo "Service Connectを切り替え中..."
aws ssm put-parameter \
    --region ap-northeast-1 \
    --name "/blue-green-app/active-backend" \
    --value $TARGET \
    --overwrite

# 旧環境を停止
echo "旧環境 ($CURRENT) を停止中..."
aws ecs update-service \
    --region ap-northeast-1 \
    --cluster blue-green-app-backend-cluster \
    --service $OLD_SERVICE \
    --desired-count 0

echo "=== 切り替え完了: $CURRENT → $TARGET ==="