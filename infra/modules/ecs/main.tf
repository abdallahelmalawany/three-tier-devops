locals {
  https_enabled = var.certificate_arn != ""

  # Tasks run in the private app subnets when a NAT gateway exists; otherwise
  # they run in public subnets with a public IP but are still only reachable
  # through the ALB security group (see README trade-offs).
  task_subnet_ids  = var.use_private_subnets ? var.private_subnet_ids : var.public_subnet_ids
  assign_public_ip = !var.use_private_subnets

  services = {
    backend = {
      port              = var.backend.port
      cpu               = var.backend.cpu
      memory            = var.backend.memory
      desired_count     = var.backend.desired_count
      health_check_path = "/api/health"
      security_group_id = var.backend_security_group_id
      needs_tmp_volume  = false
      environment = [
        { name = "PORT", value = tostring(var.backend.port) },
        { name = "DB_HOST", value = var.database.host },
        { name = "DB_PORT", value = tostring(var.database.port) },
        { name = "DB_NAME", value = var.database.name },
        { name = "DB_USER", value = var.database.username },
        { name = "DB_SSL", value = "true" },
      ]
      secrets = [
        { name = "DB_PASSWORD", valueFrom = var.database.password_parameter_arn },
      ]
    }
    frontend = {
      port              = var.frontend.port
      cpu               = var.frontend.cpu
      memory            = var.frontend.memory
      desired_count     = var.frontend.desired_count
      health_check_path = "/healthz"
      security_group_id = var.frontend_security_group_id
      needs_tmp_volume  = true # nginx writes its pid/temp files to /tmp
      environment       = []
      secrets           = []
    }
  }
}

data "aws_caller_identity" "current" {}

# ---------------------------------------------------------------------------
# Cluster and logs
# ---------------------------------------------------------------------------
resource "aws_ecs_cluster" "this" {
  name = "${var.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }
}

resource "aws_cloudwatch_log_group" "service" {
  for_each = local.services

  name              = "/ecs/${var.name_prefix}/${each.key}"
  retention_in_days = var.log_retention_days
}

# ---------------------------------------------------------------------------
# IAM: task execution role (used by the ECS agent, not by the application).
# Scoped to exactly the repositories, log groups and parameter it needs,
# instead of the broad AmazonECSTaskExecutionRolePolicy managed policy.
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "ecs_tasks_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "execution" {
  name               = "${var.name_prefix}-ecs-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
}

data "aws_iam_policy_document" "execution" {
  statement {
    sid       = "EcrAuth"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"] # this action does not support resource-level permissions
  }

  statement {
    sid = "PullImages"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
    resources = values(var.repository_arns)
  }

  statement {
    sid       = "WriteLogs"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = [for lg in aws_cloudwatch_log_group.service : "${lg.arn}:*"]
  }

  statement {
    sid       = "ReadDatabasePassword"
    actions   = ["ssm:GetParameters"]
    resources = [var.database.password_parameter_arn]
  }
}

# A customer-managed policy (not inline) so it also works in accounts that only
# allow iam:CreatePolicy + iam:AttachRolePolicy, such as KodeKloud playgrounds.
resource "aws_iam_policy" "execution" {
  provider = aws.iam_policy

  name        = "${var.name_prefix}-ecs-execution"
  description = "ECS agent: pull ${var.name_prefix} images, write its logs, read the DB password"
  policy      = data.aws_iam_policy_document.execution.json
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = aws_iam_policy.execution.arn
}

# The application itself calls no AWS APIs, so its task role has no
# permissions at all. It exists so permissions can be added explicitly later.
resource "aws_iam_role" "task" {
  name               = "${var.name_prefix}-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
}

# ---------------------------------------------------------------------------
# Application Load Balancer
# ---------------------------------------------------------------------------
resource "aws_lb" "this" {
  name                       = "${var.name_prefix}-alb"
  load_balancer_type         = "application"
  internal                   = false
  subnets                    = var.public_subnet_ids
  security_groups            = [var.alb_security_group_id]
  drop_invalid_header_fields = true
  enable_deletion_protection = false
}

resource "aws_lb_target_group" "service" {
  for_each = local.services

  name                 = "${var.name_prefix}-${each.key}"
  port                 = each.value.port
  protocol             = "HTTP"
  target_type          = "ip" # required for Fargate (awsvpc networking)
  vpc_id               = var.vpc_id
  deregistration_delay = 30

  health_check {
    path                = each.value.health_check_path
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  # With a certificate: redirect everything to HTTPS. Without one (sandbox,
  # no domain): serve the frontend over HTTP.
  default_action {
    type             = local.https_enabled ? "redirect" : "forward"
    target_group_arn = local.https_enabled ? null : aws_lb_target_group.service["frontend"].arn

    dynamic "redirect" {
      for_each = local.https_enabled ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
}

resource "aws_lb_listener" "https" {
  count = local.https_enabled ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service["frontend"].arn
  }
}

resource "aws_lb_listener_rule" "api" {
  listener_arn = local.https_enabled ? aws_lb_listener.https[0].arn : aws_lb_listener.http.arn
  priority     = 10

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service["backend"].arn
  }
}

# ---------------------------------------------------------------------------
# Task definitions and services
# ---------------------------------------------------------------------------
resource "aws_ecs_task_definition" "service" {
  for_each = local.services

  family                   = "${var.name_prefix}-${each.key}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  dynamic "volume" {
    for_each = each.value.needs_tmp_volume ? ["tmp"] : []
    content {
      name = volume.value
    }
  }

  container_definitions = jsonencode([{
    name      = each.key
    image     = "${var.repository_urls[each.key]}:${var.image_tag}"
    essential = true

    # hostPort, add, systemControls and volumesFrom repeat the values ECS fills
    # in itself; without them every plan shows a spurious replacement.
    portMappings = [{ containerPort = each.value.port, hostPort = each.value.port, protocol = "tcp" }]

    environment = each.value.environment
    secrets     = each.value.secrets

    readonlyRootFilesystem = true
    linuxParameters        = { capabilities = { add = [], drop = ["ALL"] } }
    systemControls         = []
    volumesFrom            = []
    mountPoints = each.value.needs_tmp_volume ? [
      { sourceVolume = "tmp", containerPath = "/tmp", readOnly = false }
    ] : []

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.service[each.key].name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = each.key
      }
    }
  }])
}

resource "aws_ecs_service" "service" {
  for_each = local.services

  name             = "${var.name_prefix}-${each.key}"
  cluster          = aws_ecs_cluster.this.id
  task_definition  = aws_ecs_task_definition.service[each.key].arn
  desired_count    = each.value.desired_count
  launch_type      = "FARGATE"
  platform_version = "LATEST"
  propagate_tags   = "SERVICE"

  health_check_grace_period_seconds  = 30
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  enable_execute_command             = false

  # Roll back automatically if new tasks never become healthy.
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = local.task_subnet_ids
    security_groups  = [each.value.security_group_id]
    assign_public_ip = local.assign_public_ip
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.service[each.key].arn
    container_name   = each.key
    container_port   = each.value.port
  }

  # Terraform owns the task definition *shape*; the CI/CD pipeline owns which
  # image revision is running, and auto scaling owns the task count.
  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  depends_on = [aws_lb_listener.http, aws_lb_listener_rule.api]
}

# ---------------------------------------------------------------------------
# Auto scaling (backend): target-tracking on average CPU
# ---------------------------------------------------------------------------
# Optional: some sandboxes deny application-autoscaling:TagResource, which the
# provider needs because default_tags applies to the scalable target.
resource "aws_appautoscaling_target" "backend" {
  count = var.enable_autoscaling ? 1 : 0

  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.service["backend"].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.backend.desired_count
  max_capacity       = var.backend.max_count
}

resource "aws_appautoscaling_policy" "backend_cpu" {
  count = var.enable_autoscaling ? 1 : 0

  name               = "${var.name_prefix}-backend-cpu-target"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.backend[0].service_namespace
  resource_id        = aws_appautoscaling_target.backend[0].resource_id
  scalable_dimension = aws_appautoscaling_target.backend[0].scalable_dimension

  target_tracking_scaling_policy_configuration {
    target_value       = 60
    scale_in_cooldown  = 120
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}
