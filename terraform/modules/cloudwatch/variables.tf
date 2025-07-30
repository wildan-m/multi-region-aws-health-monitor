variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for alarm notifications"
  type        = string
  default     = null
}

variable "load_balancer_arn_suffix" {
  description = "ALB ARN suffix for CloudWatch metrics"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "Target group ARN suffix for CloudWatch metrics"
  type        = string
}

variable "autoscaling_group_name" {
  description = "Auto Scaling group name"
  type        = string
}

variable "db_instance_id" {
  description = "RDS instance identifier"
  type        = string
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}