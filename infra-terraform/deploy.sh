#!/bin/bash

# =============================================================================
# Blue-Green Deployment Trigger Script
# =============================================================================

set -e

APP_NAME="blue-green-app"
REGION="ap-northeast-1"

echo "🚀 Starting Blue-Green Deployment..."

# S3バケット名を取得
BUCKET_NAME=$(aws s3api list-buckets --query "Buckets[?contains(Name, '${APP_NAME}-codepipeline-artifacts')].Name" --output text)

if [ -z "$BUCKET_NAME" ]; then
    echo "❌ S3 bucket not found. Please run 'terraform apply' first."
    exit 1
fi

echo "📦 Using S3 bucket: $BUCKET_NAME"

# 現在のディレクトリをzipに圧縮
echo "📁 Creating source package..."
zip -r source.zip . -x "*.git*" "*.terraform*" "terraform.tfstate*" "*.zip"

# S3にアップロード
echo "⬆️  Uploading source to S3..."
aws s3 cp source.zip s3://$BUCKET_NAME/source.zip

# CodePipelineを実行
echo "🔄 Starting CodePipeline..."
PIPELINE_NAME="${APP_NAME}-blue-green-pipeline"

aws codepipeline start-pipeline-execution --name $PIPELINE_NAME

echo "✅ Pipeline started successfully!"
echo "🔗 Monitor progress at: https://console.aws.amazon.com/codesuite/codepipeline/pipelines/${PIPELINE_NAME}/view"

# 実行状況を監視（オプション）
echo ""
echo "📊 Monitoring pipeline execution..."
echo "Press Ctrl+C to stop monitoring (pipeline will continue running)"

while true; do
    STATUS=$(aws codepipeline get-pipeline-execution \
        --pipeline-name $PIPELINE_NAME \
        --pipeline-execution-id $(aws codepipeline list-pipeline-executions --pipeline-name $PIPELINE_NAME --query "pipelineExecutionSummaries[0].pipelineExecutionId" --output text) \
        --query "pipelineExecution.status" --output text 2>/dev/null || echo "Unknown")
    
    echo "Current status: $STATUS"
    
    if [ "$STATUS" = "Succeeded" ]; then
        echo "🎉 Deployment completed successfully!"
        break
    elif [ "$STATUS" = "Failed" ]; then
        echo "❌ Deployment failed!"
        exit 1
    fi
    
    sleep 30
done

# クリーンアップ
rm -f source.zip

echo "🏁 Blue-Green deployment process completed!"