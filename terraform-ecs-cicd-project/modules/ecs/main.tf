# The ECS Cluster
resource "aws_ecs_cluster" "ecs-cluster" {
  name = "${var.project-name}-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }
}

# Role that allows ECS to launch tasks
data "aws_iam_role" "ecs-task-execution-role" {
  name = "ecsTaskExecutionRole"
}

# ECS task definition
resource "aws_ecs_task_definition" "ecs-task-definition" {
  family = "service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = data.aws_iam_role.ecs-task-execution-role.arn

  container_definitions = jsonencode([
    {
      name      = "abbreve"
      image     = "ajimbong/abbreve"
      cpu       = 10
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

# The ECS Service
resource "aws_ecs_service" "ecs-service" {
  name                               = "${var.project-name}-ecs-service"
  launch_type                        = "FARGATE"
  cluster                            = aws_ecs_cluster.ecs-cluster.id
  task_definition                    = aws_ecs_task_definition.ecs-task-definition.arn 
  desired_count                      = 1
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  # task tagging configuration
  enable_ecs_managed_tags = true
  propagate_tags          = "SERVICE"

  # vpc and security groups
  network_configuration {
    subnets          = [var.prv-subnet1-id, var.prv-subnet2-id]
    security_groups  = [var.web-server-sg-id]
    assign_public_ip = false
  }

  # load balancing
  load_balancer {
    target_group_arn = var.target-group-arn
    container_name   = "abbreve"
    container_port   = 80
  }
}