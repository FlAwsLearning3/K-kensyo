# Backend Service with ECS Native Blue-Green Deployment
resource "aws_ecs_service" "backend" {
  name            = "${var.app_name}-backend"
  cluster         = "blue-green-app-backend-cluster"
  task_definition = "blue-green-app-backend-blue"
  desired_count   = 1
  launch_type     = "FARGATE"
  
  network_configuration {
    subnets          = ["subnet-0b18dd7a56d7df771", "subnet-0c25c6539a40099d9"]
    security_groups  = ["sg-0cd5e007ff350bb9b"]
    assign_public_ip = true
  }

  service_connect_configuration {
    enabled   = true
    namespace = "arn:aws:servicediscovery:ap-northeast-1:546880033278:namespace/ns-hbtv5lscjbi53fni"

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