resource "aws_cloudwatch_dashboard" "sleek_regional" {
  dashboard_name = "${var.project_name}-${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.load_balancer_arn_suffix],
            [".", "TargetResponseTime", ".", "."],
            [".", "HTTPCode_Target_2XX_Count", ".", "."],
            [".", "HTTPCode_Target_4XX_Count", ".", "."],
            [".", "HTTPCode_Target_5XX_Count", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "${var.environment} - Application Load Balancer Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.autoscaling_group_name],
            [".", "NetworkIn", ".", "."],
            [".", "NetworkOut", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "${var.environment} - EC2 Instance Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.db_instance_id],
            [".", "DatabaseConnections", ".", "."],
            [".", "ReadLatency", ".", "."],
            [".", "WriteLatency", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "${var.environment} - RDS Database Metrics"
          period  = 300
        }
      },
      {
        type   = "log"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          query   = "SOURCE '/aws/ec2/sleek-health-monitor' | fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 100"
          region  = var.region
          title   = "${var.environment} - Recent Error Logs"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-dashboard-${var.environment}"
  })
}

# Custom metrics for financial services compliance
resource "aws_cloudwatch_metric_alarm" "high_response_time" {
  alarm_name          = "${var.project_name}-high-response-time-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "0.5"  # 500ms for financial services compliance
  alarm_description   = "This metric monitors ALB response time for financial services compliance"
  alarm_actions       = var.sns_topic_arn != null ? [var.sns_topic_arn] : []

  dimensions = {
    LoadBalancer = aws_lb.web.arn_suffix
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-response-time-alarm-${var.environment}"
    Compliance  = "financial-services"
    SLA         = "99.99%"
  })
}

resource "aws_cloudwatch_metric_alarm" "sla_availability" {
  alarm_name          = "${var.project_name}-sla-availability-${var.environment}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  
  metric_query {
    id          = "availability"
    return_data = "true"
    
    metric {
      metric_name = "HealthyHostCount"
      namespace   = "AWS/ApplicationELB"
      period      = "60"
      stat        = "Average"
      
      dimensions = {
        LoadBalancer = aws_lb.web.arn_suffix
        TargetGroup  = aws_lb_target_group.web.arn_suffix
      }
    }
  }
  
  threshold         = 0.9999  # 99.99% availability
  alarm_description = "SLA availability monitoring for 99.99% uptime requirement"
  alarm_actions     = var.sns_topic_arn != null ? [var.sns_topic_arn] : []

  tags = merge(var.tags, {
    Name      = "${var.project_name}-sla-alarm-${var.environment}"
    SLA       = "99.99%"
    Priority  = "critical"
  })
}

# Custom business metrics
resource "aws_cloudwatch_log_metric_filter" "error_rate" {
  name           = "${var.project_name}-error-rate-${var.environment}"
  log_group_name = aws_cloudwatch_log_group.app_logs.name
  pattern        = "[timestamp, request_id, ERROR, ...]"

  metric_transformation {
    name      = "ErrorCount"
    namespace = "Sleek/Application"
    value     = "1"
    
    default_value = "0"
  }
}

resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ec2/${var.project_name}-${var.environment}"
  retention_in_days = 14

  tags = merge(var.tags, {
    Name = "${var.project_name}-app-logs-${var.environment}"
  })
}

# Anomaly detection for proactive monitoring
resource "aws_cloudwatch_anomaly_detector" "response_time_anomaly" {
  metric_math_anomaly_detector {
    metric_data_queries {
      id = "m1"
      metric_stat {
        metric {
          metric_name = "TargetResponseTime"
          namespace   = "AWS/ApplicationELB"
          dimensions = {
            LoadBalancer = aws_lb.web.arn_suffix
          }
        }
        period = 300
        stat   = "Average"
      }
      return_data = true
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "response_time_anomaly_alarm" {
  alarm_name          = "${var.project_name}-response-time-anomaly-${var.environment}"
  comparison_operator = "LessThanLowerOrGreaterThanUpperThreshold"
  evaluation_periods  = "2"
  threshold_metric_id = "ad1"
  alarm_description   = "Response time anomaly detection for proactive monitoring"
  alarm_actions       = var.sns_topic_arn != null ? [var.sns_topic_arn] : []

  metric_query {
    id    = "ad1"
    label = "Response Time Anomaly Detection"
    
    anomaly_detector {
      metric_math_anomaly_detector {
        metric_data_queries {
          id = "m1"
          metric_stat {
            metric {
              metric_name = "TargetResponseTime"
              namespace   = "AWS/ApplicationELB"
              dimensions = {
                LoadBalancer = aws_lb.web.arn_suffix
              }
            }
            period = 300
            stat   = "Average"
          }
          return_data = true
        }
      }
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-anomaly-alarm-${var.environment}"
    Type = "proactive-monitoring"
  })
}

# Composite alarm for overall service health
resource "aws_cloudwatch_composite_alarm" "service_health" {
  alarm_name        = "${var.project_name}-service-health-${var.environment}"
  alarm_description = "Overall service health composite alarm"
  
  alarm_rule = join(" OR ", [
    "ALARM(${aws_cloudwatch_metric_alarm.high_response_time.alarm_name})",
    "ALARM(${aws_cloudwatch_metric_alarm.sla_availability.alarm_name})",
    "ALARM(${aws_cloudwatch_metric_alarm.response_time_anomaly_alarm.alarm_name})"
  ])
  
  actions_enabled = true
  alarm_actions   = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
  ok_actions      = var.sns_topic_arn != null ? [var.sns_topic_arn] : []

  tags = merge(var.tags, {
    Name = "${var.project_name}-composite-alarm-${var.environment}"
    Type = "service-health"
  })
}