# =============================================================================
# ECSネイティブブルーグリーンデプロイ with Service Connect メインリソース定義
# 
# このファイルでは以下のリソースを定義しています：
# - ECSクラスター（Service Connect有効）
# - ALB（Application Load Balancer）とBlue/Greenターゲットグループ
# - ECSタスク定義とサービス（Service Connect設定含む）
# - IAMロール（ECS実行用）
# - CloudWatchロググループ
# 
# ネットワーク関連リソースは network.tf で定義
# CodeDeployは使用せず、ECSネイティブ機能でブルーグリーンデプロイを実現
# =============================================================================

# ECS Cluster A (Frontend)
resource "aws_ecs_cluster" "frontend" {
  name = "${var.app_name}-frontend-cluster"

  service_connect_defaults {
    namespace = aws_service_discovery_http_namespace.main.arn
  }
}

# ECS Cluster B (Backend)
resource "aws_ecs_cluster" "backend" {
  name = "${var.app_name}-backend-cluster"

  service_connect_defaults {
    namespace = aws_service_discovery_http_namespace.main.arn
  }
}

# Service Discovery Namespace
resource "aws_service_discovery_http_namespace" "main" {
  name = "${var.app_name}-namespace"
}



# Frontend Task Definition
resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.app_name}-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "frontend"
      image = "nginx:alpine"
      entryPoint = ["/bin/sh"]
      command = [
        "-c",
        "echo 'Frontend v2.0 - Blue-Green Deploy Test' > /usr/share/nginx/html/index.html && echo 'server { listen 80; error_log /var/log/nginx/error.log debug; location / { root /usr/share/nginx/html; index index.html; } location /api { proxy_pass http://backend:8080/; proxy_connect_timeout 5s; proxy_send_timeout 5s; proxy_read_timeout 5s; } }' > /etc/nginx/conf.d/default.conf && exec nginx -g 'daemon off;'"
      ]
      portMappings = [
        {
          name          = "frontend-port"
          containerPort = 80
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "BACKEND_URL"
          value = "http://backend:8080"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.frontend.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# Backend Blue Task Definition
resource "aws_ecs_task_definition" "backend_blue" {
  family                   = "${var.app_name}-backend-blue"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "backend"
      image = "nginx:alpine"
      entryPoint = ["/bin/sh"]
      command = [
        "-c",
        "echo 'server { listen 8080; location / { add_header Content-Type text/plain; return 200 \"Backend BLUE - Service Connect\"; } }' > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"
      ]
      portMappings = [
        {
          name          = "backend-port"
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.backend.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# Backend Green Task Definition
resource "aws_ecs_task_definition" "backend_green" {
  family                   = "${var.app_name}-backend-green"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "backend"
      image = "nginx:alpine"
      entryPoint = ["/bin/sh"]
      command = [
        "-c",
        "echo 'server { listen 8080; location / { add_header Content-Type text/plain; return 200 \"Backend GREEN - Service Connect\"; } }' > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"
      ]
      portMappings = [
        {
          name          = "backend-port"
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.backend.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.app_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false
}

# Target Group Blue
resource "aws_lb_target_group" "blue" {
  name        = "${var.app_name}-blue"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Target Group Green
resource "aws_lb_target_group" "green" {
  name        = "${var.app_name}-green"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ALB Listener
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }

  lifecycle {
    ignore_changes = [default_action]
  }
}

# Frontend Service (Cluster A)
resource "aws_ecs_service" "frontend" {
  name                   = "${var.app_name}-frontend"
  cluster                = aws_ecs_cluster.frontend.id
  task_definition        = aws_ecs_task_definition.frontend.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.blue.arn
    container_name   = "frontend"
    container_port   = 80
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.main.arn
  }

  depends_on = [
    aws_lb_listener.main,
    aws_lb_target_group.blue,
    aws_lb_target_group.green
  ]
}

# Backend Blue Service (Cluster B) with Service Connect
resource "aws_ecs_service" "backend_blue" {
  name                   = "${var.app_name}-backend-blue"
  cluster                = aws_ecs_cluster.backend.id
  task_definition        = aws_ecs_task_definition.backend_blue.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  force_new_deployment   = true
  enable_execute_command = true
  
  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.main.arn

    service {
      port_name      = "backend-port"
      discovery_name = "backend"
      
      client_alias {
        port     = 8080
        dns_name = "backend"
      }
    }
  }
}

# Backend Green Service (Cluster B) - Initially stopped
resource "aws_ecs_service" "backend_green" {
  name            = "${var.app_name}-backend-green"
  cluster         = aws_ecs_cluster.backend.id
  task_definition = aws_ecs_task_definition.backend_green.arn
  desired_count   = 0
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.main.arn

    service {
      port_name      = "backend-port"
      discovery_name = "backend"
      
      client_alias {
        port     = 8080
        dns_name = "backend"
      }
    }
  }


}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${var.app_name}-frontend"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.app_name}-backend"
  retention_in_days = 7
}

# IAM Role for ECS Execution
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.app_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Role for ECS Task (ECS Exec)
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.app_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_exec_policy" {
  name = "${var.app_name}-ecs-exec-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })
}





