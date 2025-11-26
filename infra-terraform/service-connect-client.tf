# =============================================================================
# Service Connectクライアントサービス定義（テスト用）
# 
# このファイルでは以下のリソースを定義しています：
# - Service Connect経由でメインアプリケーションにアクセスするテストクライアント
# - クライアント用のCloudWatchロググループ
# - クライアントECSサービス（オプション）
# 
# クライアントは30秒ごとに"app:8080"にアクセスし、Service Connectの動作をテストします
# enable_client変数で有効/無効を制御可能
# =============================================================================

# Service Connect Client Task Definition (for testing)
resource "aws_ecs_task_definition" "client" {
  family                   = "${var.app_name}-client"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "client"
      image = "curlimages/curl:latest"
      command = [
        "sh", "-c",
        "while true; do echo 'Testing Service Connect...'; curl -s http://app:${var.container_port}/ || echo 'Connection failed'; sleep 30; done"
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.client.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# CloudWatch Log Group for Client
resource "aws_cloudwatch_log_group" "client" {
  name              = "/ecs/${var.app_name}-client"
  retention_in_days = 7
}

# ECS Service for Client (optional - for testing Service Connect)
resource "aws_ecs_service" "client" {
  count           = var.enable_client ? 1 : 0
  name            = "${var.app_name}-client"
  cluster         = aws_ecs_cluster.frontend.id
  task_definition = aws_ecs_task_definition.client.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.main.arn
  }
}