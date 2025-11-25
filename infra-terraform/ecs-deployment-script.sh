#!/bin/bash

# ECS Blue/Green Deployment Script
set -e

SERVICE_NAME="blue-green-app"
CLUSTER_NAME="blue-green-cluster"
TASK_FAMILY="blue-green-app"
NEW_IMAGE_URI="$1"

if [ -z "$NEW_IMAGE_URI" ]; then
    echo "Usage: $0 <new-image-uri>"
    exit 1
fi

echo "Starting Blue/Green deployment..."
echo "Service: $SERVICE_NAME"
echo "Cluster: $CLUSTER_NAME"
echo "New Image: $NEW_IMAGE_URI"

# Get current task definition
CURRENT_TASK_DEF=$(aws ecs describe-task-definition --task-definition $TASK_FAMILY --query 'taskDefinition')

# Create new task definition with updated image
NEW_TASK_DEF=$(echo $CURRENT_TASK_DEF | jq --arg IMAGE "$NEW_IMAGE_URI" '
    .containerDefinitions[0].image = $IMAGE |
    del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .placementConstraints, .compatibilities, .registeredAt, .registeredBy)
')

# Register new task definition
NEW_REVISION=$(aws ecs register-task-definition --cli-input-json "$NEW_TASK_DEF" --query 'taskDefinition.revision')

echo "New task definition revision: $NEW_REVISION"

# Update service with new task definition
aws ecs update-service \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --task-definition $TASK_FAMILY:$NEW_REVISION

echo "Deployment initiated. Monitoring deployment status..."

# Wait for deployment to complete
aws ecs wait services-stable \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME

echo "Blue/Green deployment completed successfully!"