# ECS関連
output "frontend_cluster_name" {
  description = "Frontend ECS cluster name"
  value       = aws_ecs_cluster.frontend.name
}

output "backend_cluster_name" {
  description = "Backend ECS cluster name"
  value       = aws_ecs_cluster.backend.name
}

output "frontend_service_name" {
  description = "Frontend ECS service name"
  value       = aws_ecs_service.frontend.name
}

output "backend_service_name" {
  description = "Backend ECS service name"
  value       = aws_ecs_service.backend.name
}

output "service_connect_endpoint" {
  description = "Service Connect endpoint"
  value       = "app:${var.container_port}"
}

# ネットワーク関連
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

# ALB関連
output "load_balancer_dns" {
  description = "Load balancer DNS name"
  value       = aws_lb.main.dns_name
}

output "blue_target_group_arn" {
  description = "Blue target group ARN"
  value       = aws_lb_target_group.blue.arn
}

output "green_target_group_arn" {
  description = "Green target group ARN"
  value       = aws_lb_target_group.green.arn
}

output "listener_arn" {
  description = "ALB listener ARN"
  value       = aws_lb_listener.main.arn
}