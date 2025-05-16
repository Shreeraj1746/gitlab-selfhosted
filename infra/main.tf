resource "aws_instance" "gitlab" {
  ami                         = "ami-0a6517a32d497bb2c" # Amazon Linux 2023 ARM64 for ap-south-1, Python 3.9+
  instance_type               = "t4g.medium"            # 2 vCPU, 4GB RAM, meets GitLab CE minimum requirements
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  key_name                    = "basic-cloud-app-key-pair"

  vpc_security_group_ids = [aws_security_group.gitlab_sg.id]

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
  }

  tags = {
    Name = "GitLab-Instance"
  }

  iam_instance_profile = aws_iam_instance_profile.gitlab_instance_profile.name
}

resource "aws_security_group" "gitlab_sg" {
  name_prefix = "gitlab-sg-"
  vpc_id      = aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow ICMP (ping) from anywhere
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"
}

resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "GitLab-VPC"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
  tags = {
    Name = "GitLab-IGW"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.default.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }
  tags = {
    Name = "GitLab-Public-RT"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public.id
}

resource "aws_lb" "gitlab_alb" {
  count                      = var.enable_alb ? 1 : 0
  name                       = "gitlab-alb"
  internal                   = false
  load_balancer_type         = "application"
  subnets                    = [aws_subnet.public_subnet.id]
  security_groups            = [aws_security_group.gitlab_sg.id]
  enable_deletion_protection = false
  tags = {
    Name = "GitLab-ALB"
  }
}

resource "aws_lb_target_group" "gitlab_tg" {
  count    = var.enable_alb ? 1 : 0
  name     = "gitlab-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.default.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "gitlab_listener" {
  count             = var.enable_alb ? 1 : 0
  load_balancer_arn = aws_lb.gitlab_alb[0].arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gitlab_tg[0].arn
  }
}

resource "aws_lb_target_group_attachment" "gitlab_attachment" {
  count            = var.enable_alb ? 1 : 0
  target_group_arn = aws_lb_target_group.gitlab_tg[0].arn
  target_id        = aws_instance.gitlab.id
  port             = 80
}

resource "aws_s3_bucket" "gitlab_backups" {
  count         = var.enable_s3_backups ? 1 : 0
  bucket        = "${var.s3_bucket_prefix}-gitlab-backups"
  force_destroy = false
  tags = {
    Purpose = "GitLab Backups"
  }
}

resource "aws_s3_bucket" "gitlab_lfs" {
  count         = var.enable_s3_lfs ? 1 : 0
  bucket        = "${var.s3_bucket_prefix}-gitlab-lfs"
  force_destroy = false
  tags = {
    Purpose = "GitLab LFS"
  }
}

resource "aws_s3_bucket" "gitlab_artifacts" {
  count         = var.enable_s3_artifacts ? 1 : 0
  bucket        = "${var.s3_bucket_prefix}-gitlab-artifacts"
  force_destroy = false
  tags = {
    Purpose = "GitLab Artifacts"
  }
}

resource "aws_s3_bucket" "gitlab_packages" {
  count         = var.enable_s3_packages ? 1 : 0
  bucket        = "${var.s3_bucket_prefix}-gitlab-packages"
  force_destroy = false
  tags = {
    Purpose = "GitLab Packages"
  }
}

resource "aws_iam_role" "gitlab_instance_role" {
  name = "gitlab-instance-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
  tags = {
    Name = "GitLab-Instance-Role"
  }
}

locals {
  s3_arns = compact(
    concat(
      var.enable_s3_backups && length(aws_s3_bucket.gitlab_backups) > 0 ? [aws_s3_bucket.gitlab_backups[0].arn, "${aws_s3_bucket.gitlab_backups[0].arn}/*"] : [],
      var.enable_s3_lfs && length(aws_s3_bucket.gitlab_lfs) > 0 ? [aws_s3_bucket.gitlab_lfs[0].arn, "${aws_s3_bucket.gitlab_lfs[0].arn}/*"] : [],
      var.enable_s3_artifacts && length(aws_s3_bucket.gitlab_artifacts) > 0 ? [aws_s3_bucket.gitlab_artifacts[0].arn, "${aws_s3_bucket.gitlab_artifacts[0].arn}/*"] : [],
      var.enable_s3_packages && length(aws_s3_bucket.gitlab_packages) > 0 ? [aws_s3_bucket.gitlab_packages[0].arn, "${aws_s3_bucket.gitlab_packages[0].arn}/*"] : []
    )
  )
  s3_statement = length(local.s3_arns) > 0 ? [{
    Effect = "Allow",
    Action = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ],
    Resource = local.s3_arns
  }] : []
  iam_policy_statements = concat(
    local.s3_statement,
    [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  )
}

resource "aws_iam_role_policy" "gitlab_instance_policy" {
  name = "gitlab-instance-policy"
  role = aws_iam_role.gitlab_instance_role.id
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = local.iam_policy_statements
  })
}

resource "aws_iam_instance_profile" "gitlab_instance_profile" {
  name = "gitlab-instance-profile"
  role = aws_iam_role.gitlab_instance_role.name
}

resource "aws_backup_vault" "gitlab_backup_vault" {
  count = var.enable_paid_features ? 1 : 0
  name  = "gitlab-backup-vault"
  tags = {
    Name = "GitLab-Backup-Vault"
  }
}

resource "aws_backup_plan" "gitlab_backup_plan" {
  count = var.enable_paid_features ? 1 : 0
  name  = "gitlab-backup-plan"
  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.gitlab_backup_vault[0].name
    schedule          = "cron(0 0 * * ? *)"
    lifecycle {
      delete_after = 7
    }
  }
}

resource "aws_backup_selection" "gitlab_backup_selection" {
  count        = var.enable_paid_features ? 1 : 0
  iam_role_arn = aws_iam_role.gitlab_instance_role.arn
  name         = "gitlab-backup-selection"
  plan_id      = aws_backup_plan.gitlab_backup_plan[0].id
  resources    = [aws_instance.gitlab.arn]
}
