# Blue-Green切り替え用の変数とリソース

variable "target_group" {
  description = "Active target group (blue or green)"
  type        = string
  default     = "blue"
}

# ALB Listener Rule for Blue-Green switching
resource "aws_lb_listener_rule" "blue_green_switch" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = var.target_group == "blue" ? aws_lb_target_group.blue.arn : aws_lb_target_group.green.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}