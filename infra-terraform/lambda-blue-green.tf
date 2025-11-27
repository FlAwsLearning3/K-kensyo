# =============================================================================
# Lambda Blue/Green Deployment Controller
# 
# ECSサービスのデプロイメントを監視し、ターゲットグループの切り替えを制御
# =============================================================================

# Lambda Function for Blue/Green Deployment
resource "aws_lambda_function" "blue_green_controller" {
  filename         = "blue_green_controller.zip"
  function_name    = "${var.app_name}-blue-green-controller"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300

  environment {
    variables = {
      CLUSTER_NAME           = aws_ecs_cluster.backend.name
      SERVICE_NAME          = aws_ecs_service.backend.name
      BLUE_TARGET_GROUP_ARN = aws_lb_target_group.blue.arn
      GREEN_TARGET_GROUP_ARN = aws_lb_target_group.green.arn
      LISTENER_ARN          = aws_lb_listener.main.arn
    }
  }

  depends_on = [data.archive_file.lambda_zip]
}

# Lambda function code
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "blue_green_controller.zip"
  source {
    content = <<EOF
import json
import boto3
import time
import os

ecs = boto3.client('ecs')
elbv2 = boto3.client('elbv2')

def handler(event, context):
    cluster_name = os.environ['CLUSTER_NAME']
    service_name = os.environ['SERVICE_NAME']
    blue_tg_arn = os.environ['BLUE_TARGET_GROUP_ARN']
    green_tg_arn = os.environ['GREEN_TARGET_GROUP_ARN']
    listener_arn = os.environ['LISTENER_ARN']
    
    # 現在のタスク定義を取得
    task_def = ecs.describe_task_definition(taskDefinition=service_name)['taskDefinition']
    
    # 新しいタスク定義を作成（最新のECRイメージを使用）
    new_task_def = {
        'family': task_def['family'],
        'networkMode': task_def['networkMode'],
        'requiresCompatibilities': task_def['requiresCompatibilities'],
        'cpu': task_def['cpu'],
        'memory': task_def['memory'],
        'executionRoleArn': task_def['executionRoleArn'],
        'containerDefinitions': task_def['containerDefinitions']
    }
    
    # 新しいタスク定義を登録
    new_task_def_arn = ecs.register_task_definition(**new_task_def)['taskDefinition']['taskDefinitionArn']
    
    # 現在のリスナー設定を取得
    listener = elbv2.describe_listeners(ListenerArns=[listener_arn])['Listeners'][0]
    current_tg = listener['DefaultActions'][0]['TargetGroupArn']
    
    # 次のターゲットグループを決定
    next_tg = green_tg_arn if current_tg == blue_tg_arn else blue_tg_arn
    
    # ECSサービスを新しいタスク定義とターゲットグループで更新
    ecs.update_service(
        cluster=cluster_name,
        service=service_name,
        taskDefinition=new_task_def_arn,
        loadBalancers=[{
            'targetGroupArn': next_tg,
            'containerName': 'backend',
            'containerPort': 8080
        }]
    )
    
    # サービスが安定するまで待機
    waiter = ecs.get_waiter('services_stable')
    waiter.wait(cluster=cluster_name, services=[service_name])
    
    # リスナーのターゲットグループを切り替え
    elbv2.modify_listener(
        ListenerArn=listener_arn,
        DefaultActions=[{
            'Type': 'forward',
            'TargetGroupArn': next_tg
        }]
    )
    
    return {
        'statusCode': 200,
        'body': json.dumps(f'Deployed new version and switched to {next_tg}')
    }
EOF
    filename = "index.py"
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.app_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  role = aws_iam_role.lambda_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:UpdateService"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:ModifyListener"
        ]
        Resource = "*"
      }
    ]
  })
}