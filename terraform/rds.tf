# RDS PostgreSQL Instance
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}db"

  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = var.db_instance_class
  allocated_storage    = var.db_allocated_storage
  storage_type         = "gp3"
  storage_encrypted    = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az               = true 
  publicly_accessible    = false
  backup_retention_period = 0
  backup_window          = "03:00-04:00"
  maintenance_window     = "mon:04:00-mon:05:00"

  skip_final_snapshot       = false 
  final_snapshot_identifier = "${var.project_name}-db-final-snapshot"

  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]

  auto_minor_version_upgrade = true
  deletion_protection        = false 
  
  tags = {
    Name = "${var.project_name}db"
  }
}