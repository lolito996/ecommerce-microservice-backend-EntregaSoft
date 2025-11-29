# RDS Module - PostgreSQL Database
# Creates RDS instance with automated backups and multi-AZ for production

resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-${var.project_name}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-${var.project_name}-db-subnet-group"
    }
  )
}

resource "aws_db_parameter_group" "main" {
  name   = "${var.environment}-${var.project_name}-pg-params"
  family = var.parameter_group_family

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-${var.project_name}-db-params"
    }
  )
}

resource "random_password" "master_password" {
  length  = 16
  special = true
}

resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.environment}-${var.project_name}-db-master-password"
  recovery_window_in_days = var.environment == "prod" ? 30 : 0

  tags = var.common_tags
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.master_password.result
}

resource "aws_db_instance" "main" {
  identifier     = "${var.environment}-${var.project_name}-db"
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted

  db_name  = var.database_name
  username = var.master_username
  password = random_password.master_password.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  parameter_group_name   = aws_db_parameter_group.main.name
  vpc_security_group_ids = var.security_group_ids

  multi_az               = var.multi_az
  publicly_accessible    = false
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.environment}-${var.project_name}-db-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  deletion_protection = var.deletion_protection

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-${var.project_name}-db"
    }
  )
}
