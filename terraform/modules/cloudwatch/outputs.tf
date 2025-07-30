output "dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.sleek_regional.dashboard_name}"
}

output "composite_alarm_arn" {
  description = "ARN of the composite service health alarm"
  value       = aws_cloudwatch_composite_alarm.service_health.arn
}

output "log_group_name" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.app_logs.name
}