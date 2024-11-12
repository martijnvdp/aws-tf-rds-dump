resource "aws_batch_compute_environment" "default" {
  compute_environment_name = var.name

  compute_resources {
    max_vcpus = 4

    security_group_ids = [
      aws_security_group.sample.id
    ]

    subnets = [
      aws_subnet.sample.id
    ]

    type = "FARGATE"
  }

  service_role = aws_iam_role.aws_batch_service_role.arn
  type         = "MANAGED"
  depends_on   = [aws_iam_role_policy_attachment.aws_batch_service_role]
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.name}_batch_exec_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_efs_file_system" "temp" {
  creation_token = var.name

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_batch_job_definition" "test" {
  name = "${var.name}_batch_job_definition"
  type = "container"

  platform_capabilities = [
    "FARGATE",
  ]

  container_properties = jsonencode({
    command = var.container.command
    image   = var.container.image
    environment = [
      {
        name  = ""
        value = ""
      }
    ]
    jobRoleArn = var.iam_role_arn

    fargatePlatformConfiguration = {
      platformVersion = "LATEST"
    }

    resourceRequirements = [
      {
        type  = "VCPU"
        value = "0.5"
      },
      {
        type  = "MEMORY"
        value = "1024"
      }
    ]
    volumes = [
      {
        fileSystemId = aws_efs_file_system.temp.id
        host = {
          sourcePath = "/tmp"
        }
        name = "tmp"
      }
    ]

    environment = [
      {
        name  = "bucket"
        value = var.bucket
      }
    ]

    mountPoints = [
      {
        sourceVolume  = "tmp"
        containerPath = "/tmp"
        readOnly      = false
      }
    ]

    executionRoleArn = aws_iam_role.ecs_task_execution_role.arn
  })
}

resource "aws_batch_scheduling_policy" "default" {
  name = var.name

  fair_share_policy {
    compute_reservation = 1
    share_decay_seconds = 3600

    share_distribution {
      share_identifier = "A1*"
      weight_factor    = 0.1
    }
  }
}

resource "aws_batch_job_queue" "example" {
  name = "${var.name}-batch-job-queue"

  scheduling_policy_arn = aws_batch_scheduling_policy.default.arn
  state                 = "ENABLED"
  priority              = 1

  compute_environment_order {
    order               = 1
    compute_environment = aws_batch_compute_environment.default.arn
  }
}
