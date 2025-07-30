# Sleek Multi-Region Infrastructure Incident Response Runbook

## Overview
This runbook provides step-by-step procedures for responding to incidents in Sleek's multi-region infrastructure across Singapore, Hong Kong, Australia, and UK.

## Emergency Contacts

### Primary On-Call Team
- **Sarah Chen** (Infrastructure Lead): +65-xxxx-xxxx
- **Marcus Wong** (DevOps Engineer): +852-xxxx-xxxx  
- **Priya Sharma** (Site Reliability Engineer): +61-xxxx-xxxx
- **James Mitchell** (Systems Administrator): +44-xxxx-xxxx

### Escalation Chain
1. **Level 1**: On-call engineer (immediate response)
2. **Level 2**: Team lead (5 minutes)
3. **Level 3**: Engineering manager (15 minutes)
4. **Level 4**: VP Engineering (30 minutes)

## Incident Severity Levels

### P0 - Critical (Response Time: Immediate)
- Complete service outage affecting all regions
- Data breach or security incident
- Financial services compliance violation
- Multi-region infrastructure failure

### P1 - High (Response Time: 15 minutes)
- Single region complete outage
- Database unavailability
- SLA violation (below 99.99% availability)
- Payment processing failures

### P2 - Medium (Response Time: 1 hour)
- Partial service degradation
- High response times (>500ms)
- Individual component failures
- Monitoring system issues

### P3 - Low (Response Time: 4 hours)
- Non-critical feature issues
- Cosmetic problems
- Documentation updates needed

## Common Incident Response Procedures

### 1. Single Region Outage

#### Symptoms
- Prometheus alerts for specific region
- Health checks failing in one region
- Customer reports from specific geographic area

#### Immediate Actions (First 5 minutes)
1. **Acknowledge the incident** in PagerDuty
2. **Verify the outage** using multiple monitoring sources:
   ```bash
   # Check Grafana dashboard
   # Verify Prometheus metrics
   # Run synthetic health checks
   ./scripts/health-check-synthetic.py --region singapore
   ```
3. **Check AWS Service Health** for the affected region
4. **Notify stakeholders** via Slack #sleek-incidents

#### Investigation Steps
1. **Check infrastructure status**:
   ```bash
   # SSH to bastion host in affected region
   aws ec2 describe-instances --region ap-southeast-1 --filters "Name=tag:Project,Values=sleek-health-monitor"
   
   # Check load balancer health
   aws elbv2 describe-target-health --target-group-arn <target-group-arn> --region ap-southeast-1
   
   # Verify RDS status
   aws rds describe-db-instances --region ap-southeast-1
   ```

2. **Review recent changes**:
   - Check recent deployments
   - Review Terraform state changes
   - Check CloudWatch logs for errors

3. **Network connectivity**:
   ```bash
   # Test connectivity from other regions
   curl -I https://singapore-lb.sleek-monitor.local/health
   
   # Check DNS resolution
   nslookup singapore-lb.sleek-monitor.local
   ```

#### Resolution Steps
1. **Auto Scaling Issues**:
   ```bash
   # Check Auto Scaling Group
   aws autoscaling describe-auto-scaling-groups --region ap-southeast-1
   
   # Force instance refresh if needed
   aws autoscaling start-instance-refresh --auto-scaling-group-name sleek-web-asg-singapore
   ```

2. **Load Balancer Issues**:
   ```bash
   # Check target health
   aws elbv2 describe-target-health --target-group-arn <arn>
   
   # Review ALB logs in CloudWatch
   ```

3. **Database Issues**:
   ```bash
   # Check RDS status
   aws rds describe-db-instances --db-instance-identifier sleek-db-singapore
   
   # Review database logs
   aws logs filter-log-events --log-group-name /aws/rds/instance/sleek-db-singapore/error
   ```

### 2. Multi-Region Outage (P0 Critical)

#### Immediate Actions (First 2 minutes)
1. **Declare major incident** in PagerDuty
2. **Activate incident bridge**: conference call with all team leads
3. **Post in #sleek-critical** Slack channel
4. **Check for AWS region-wide issues**: https://status.aws.amazon.com/

#### Disaster Recovery Steps
1. **Assess blast radius**:
   ```bash
   # Check all regions
   for region in singapore hongkong australia uk; do
     echo "Checking $region..."
     ./scripts/health-check-synthetic.py --region $region
   done
   ```

2. **Activate backup regions** if available
3. **Enable maintenance mode** to prevent data corruption
4. **Contact AWS Support** (Enterprise Support)

### 3. SLA Violation (P1 High)

#### Symptoms
- Availability drops below 99.99%
- Response times exceed 500ms for financial services
- PagerDuty alert for SLA compliance

#### Response Steps
1. **Calculate current availability**:
   ```bash
   # Query Prometheus for availability metrics
   curl -G 'http://prometheus:9090/api/v1/query' \
     --data-urlencode 'query=avg(probe_success{job=~"blackbox-http-.*"}) * 100'
   ```

2. **Identify root cause**:
   - Check infrastructure metrics
   - Review application logs
   - Analyze network latency

3. **Implement immediate fixes**:
   - Scale up resources if needed
   - Route traffic to healthy regions
   - Optimize database queries

4. **Document for compliance**:
   - Record exact downtime
   - Calculate SLA credits if applicable
   - Prepare customer communication

### 4. Database Performance Issues

#### Symptoms
- High database CPU (>80%)
- Slow query performance
- Connection pool exhaustion

#### Investigation
```bash
# Check RDS metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name CPUUtilization \
  --dimensions Name=DBInstanceIdentifier,Value=sleek-db-singapore \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T01:00:00Z \
  --period 300 \
  --statistics Average

# Review slow query logs
aws logs filter-log-events \
  --log-group-name /aws/rds/instance/sleek-db-singapore/slowquery \
  --start-time 1640995200000
```

#### Resolution
1. **Immediate**: Scale up RDS instance if needed
2. **Short-term**: Optimize problematic queries
3. **Long-term**: Implement read replicas, database sharding

### 5. Security Incident

#### Immediate Actions (First 1 minute)
1. **Isolate affected systems**
2. **Preserve evidence** (don't restart instances)
3. **Contact security team**
4. **Enable detailed logging**

#### Investigation Steps
1. **Check CloudTrail** for suspicious API calls:
   ```bash
   aws logs filter-log-events \
     --log-group-name CloudTrail/sleek-security \
     --filter-pattern "{ $.errorCode = \"*UnauthorizedOperation*\" }"
   ```

2. **Review VPC Flow Logs** for unusual network activity
3. **Check GuardDuty findings**
4. **Analyze access patterns**

## Post-Incident Procedures

### 1. Incident Resolution
1. **Verify full service restoration**
2. **Update incident ticket** with resolution details
3. **Notify all stakeholders**
4. **Close PagerDuty incident**

### 2. Post-Mortem Process
1. **Schedule post-mortem meeting** within 48 hours
2. **Create incident timeline**
3. **Identify root cause**
4. **Document lessons learned**
5. **Create action items** for prevention

### 3. Post-Mortem Template
```markdown
# Incident Post-Mortem: [Date] - [Brief Description]

## Summary
Brief description of what happened

## Timeline
- HH:MM - Incident detected
- HH:MM - Response team assembled
- HH:MM - Root cause identified
- HH:MM - Resolution implemented
- HH:MM - Service restored

## Root Cause
Detailed explanation of what caused the incident

## Impact
- Duration: X minutes
- Affected users: X%
- Financial impact: $X
- SLA breach: Yes/No

## What Went Well
- List positive aspects of response

## What Could Be Improved
- List areas for improvement

## Action Items
- [ ] Task 1 (Owner: Name, Due: Date)
- [ ] Task 2 (Owner: Name, Due: Date)
```

## Monitoring and Alerting Resources

### Key URLs
- **Grafana**: http://localhost:3000
- **Prometheus**: http://localhost:9090
- **AlertManager**: http://localhost:9093
- **AWS Console**: https://console.aws.amazon.com
- **PagerDuty**: https://sleek.pagerduty.com

### Critical Metrics to Monitor
- Service availability per region
- Response time percentiles
- Error rates
- Database performance
- Infrastructure resource utilization

### Runbook Validation
This runbook should be tested quarterly with:
- Tabletop exercises
- Synthetic incident drills
- Documentation reviews
- Team training updates

---
**Last Updated**: 2024-01-30  
**Next Review**: 2024-04-30  
**Owner**: Infrastructure Team