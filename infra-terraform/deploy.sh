#!/bin/bash

# Blue/Green Deployment Script for ECS with Service Connect

set -e

# Variables
APP_NAME=${1:-"blue-green-app"}
NEW_IMAGE=${2:-"nginx:latest"}
REGION=${3:-"ap-northeast-1"}

echo "Starting Blue/Green deployment for $APP_NAME with image $NEW_IMAGE"

# Get current task definition
TASK_DEFINITION=$(aws ecs describe-task-definition \
    --task-definition $APP_NAME \
    --region $REGION \
    --query 'taskDefinition' \
    --output json)

# Create new task definition with updated image
NEW_TASK_DEFINITION=$(echo $TASK_DEFINITION | jq --arg IMAGE "$NEW_IMAGE" '
    .containerDefinitions[0].image = $IMAGE |
    del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .placementConstraints, .compatibilities, .registeredAt, .registeredBy)
')

# Register new task definition
NEW_TASK_DEF_ARN=$(echo $NEW_TASK_DEFINITION | aws ecs register-task-definition \
    --region $REGION \
    --cli-input-json file:///dev/stdin \
    --query 'taskDefinition.taskDefinitionArn' \
    --output text)

echo "New task definition registered: $NEW_TASK_DEF_ARN"

# Create CodeDeploy deployment
DEPLOYMENT_ID=$(aws deploy create-deployment \
    --application-name $APP_NAME \
    --deployment-group-name "${APP_NAME}-deployment-group" \
    --region $REGION \
    --revision '{
        "revisionType": "AppSpecContent",
        "appSpecContent": {
            "content": "{\"version\":\"0.0\",\"Resources\":[{\"TargetService\":{\"Type\":\"AWS::ECS::Service\",\"Properties\":{\"TaskDefinition\":\"'$NEW_TASK_DEF_ARN'\",\"LoadBalancerInfo\":{\"ContainerName\":\"app\",\"ContainerPort\":'$CONTAINER_PORT'}}}}]}"
        }
    }' \
    --query 'deploymentId' \
    --output text)

echo "Deployment started with ID: $DEPLOYMENT_ID"

# Wait for deployment to complete
echo "Waiting for deployment to complete..."
aws deploy wait deployment-successful \
    --deployment-id $DEPLOYMENT_ID \
    --region $REGION

echo "Blue/Green deployment completed successfully!"
echo "Service Connect endpoint: app:8080"