# =============================================================================
# Test Client Service for Service Connect Verification
# 
# Service Connect経由でバックエンドサービスにアクセスするテスト用クライアント
# =============================================================================

# Test Client Task Definition
resource "aws_ecs_task_definition" "test_client" {
  count                    = var.enable_client ? 1 : 0
  family                   = "${var.app_name}-test-client"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "test-client"
      image = "curlimages/curl:latest"
      command = [
        "sh", "-c", 
        "while true; do echo 'Testing Service Connect...'; curl -s http://backend:${var.container_port}/health || echo 'Connection failed'; sleep 30; done"
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.test_client[0].name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# Test Client Service
resource "aws_ecs_service" "test_client" {
  count           = var.enable_client ? 1 : 0
  name            = "${var.app_name}-test-client"
  cluster         = aws_ecs_cluster.frontend.id
  task_definition = aws_ecs_task_definition.test_client[0].arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.main.arn
  }
}

# CloudWatch Log Group for Test Client
resource "aws_cloudwatch_log_group" "test_client" {
  count             = var.enable_client ? 1 : 0
  name              = "/ecs/${var.app_name}-test-client"
  retention_in_days = 7
}