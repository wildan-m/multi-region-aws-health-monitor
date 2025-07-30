# 🌏 Sleek Multi-Region Infrastructure Monitoring Dashboard

A comprehensive monitoring and alerting solution demonstrating enterprise-grade multi-region infrastructure across Singapore, Hong Kong, Australia, and UK, designed to showcase expertise in global financial services operations.

[![Infrastructure](https://img.shields.io/badge/Infrastructure-AWS-orange.svg)](https://aws.amazon.com/)
[![Monitoring](https://img.shields.io/badge/Monitoring-Prometheus%20%2B%20Grafana-blue.svg)](https://prometheus.io/)
[![IaC](https://img.shields.io/badge/IaC-Terraform-purple.svg)](https://terraform.io/)
[![Alerting](https://img.shields.io/badge/Alerting-PagerDuty-green.svg)](https://pagerduty.com/)

## 🎯 Project Overview

This project demonstrates a production-ready, multi-region monitoring solution that meets financial services requirements with 99.99% SLA, sub-500ms response times, and comprehensive incident management.

### Key Features

- **🌐 Multi-Region Architecture**: Infrastructure across 4 AWS regions matching Sleek's global presence
- **📊 Real-time Monitoring**: Prometheus + Grafana stack with custom business metrics  
- **🚨 Intelligent Alerting**: PagerDuty integration with escalation policies
- **🔍 Synthetic Monitoring**: Automated health checks and user journey simulation
- **📋 Incident Management**: Complete runbooks and operational procedures
- **💰 Cost Optimization**: Resource tagging, monitoring, and optimization strategies
- **🔒 Security & Compliance**: Financial services security standards implementation

## 🏗️ Architecture

### Regional Distribution
- **Singapore** (`ap-southeast-1`) - Primary APAC hub
- **Hong Kong** (`ap-east-1`) - Greater China operations  
- **Australia** (`ap-southeast-2`) - ANZ market
- **United Kingdom** (`eu-west-2`) - European operations

### Infrastructure Components

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Singapore     │    │   Hong Kong     │    │   Australia     │    │   United Kingdom│
│                 │    │                 │    │                 │    │                 │
│ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │     ALB     │ │    │ │     ALB     │ │    │ │     ALB     │ │    │ │     ALB     │ │
│ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │
│        │        │    │        │        │    │        │        │    │        │        │
│ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │ EC2 Cluster │ │    │ │ EC2 Cluster │ │    │ │ EC2 Cluster │ │    │ │ EC2 Cluster │ │
│ │ (Auto Scale)│ │    │ │ (Auto Scale)│ │    │ │ (Auto Scale)│ │    │ │ (Auto Scale)│ │
│ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │
│        │        │    │        │        │    │        │        │    │        │        │
│ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │ RDS MySQL   │ │    │ │ RDS MySQL   │ │    │ │ RDS MySQL   │ │    │ │ RDS MySQL   │ │
│ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │
└─────────────────┘    └─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Monitoring Stack

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                               Monitoring & Alerting                                 │
├─────────────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────────────┐   │
│  │   Grafana   │    │ Prometheus  │    │AlertManager │    │     PagerDuty       │   │
│  │ Dashboards  │────│   Metrics   │────│   Rules     │────│   Escalation       │   │
│  │   :3000     │    │    :9090    │    │   :9093     │    │   Policies          │   │
│  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────────────┘   │
│           │                   │                   │                                  │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                           │
│  │   Node      │    │  Blackbox   │    │  CloudWatch │                           │
│  │ Exporters   │    │  Exporter   │    │   Metrics   │                           │
│  └─────────────┘    └─────────────┘    └─────────────┘                           │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- Docker and Docker Compose
- Python 3.8+ with pip
- Git

### 1. Clone and Setup

```bash
git clone <repository-url>
cd multi-region-aws-health-monitor

# Install Python dependencies for health checks
pip install -r requirements.txt
```

### 2. Configure AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID, Secret Key, and default region
```

### 3. Deploy Infrastructure

```bash
# Plan deployment across all regions
./scripts/deploy-infrastructure.sh plan

# Deploy to all regions (will prompt for confirmation)
./scripts/deploy-infrastructure.sh deploy
```

### 4. Start Monitoring Stack

```bash
# Start Prometheus, Grafana, and AlertManager
docker-compose up -d

# Access dashboards
open http://localhost:3000  # Grafana (admin/sleek-monitor-2024)
open http://localhost:9090  # Prometheus
open http://localhost:9093  # AlertManager
```

### 5. Run Health Checks

```bash
# Single health check run
./scripts/health-check-synthetic.py

# Continuous monitoring
./scripts/health-check-synthetic.py --continuous
```

## 📊 Monitoring & Dashboards

### Grafana Dashboards

Access Grafana at `http://localhost:3000` with credentials:
- **Username**: `admin`
- **Password**: `sleek-monitor-2024`

#### Available Dashboards:
- **Sleek Multi-Region Overview**: High-level health across all regions
- **Regional Performance**: Detailed metrics per region
- **SLA Compliance**: 99.99% availability tracking
- **Financial Services Metrics**: Sub-500ms response time monitoring

### Key Metrics Monitored

- **Availability**: Service uptime per region
- **Response Time**: P50, P95, P99 percentiles
- **Error Rates**: 4xx/5xx HTTP errors
- **Infrastructure**: CPU, Memory, Disk usage
- **Database**: Connection count, query performance
- **Business**: Transaction volume, user activities

## 🚨 Alerting & Incident Response

### PagerDuty Integration

The system includes three-tier escalation policies:

1. **Critical Infrastructure** → Immediate response (0 min)
2. **SLA Violations** → Fast response (2 min)  
3. **Disaster Recovery** → Executive escalation (0 min)

### Alert Severity Levels

- **P0 - Critical**: Multi-region outage, security breach
- **P1 - High**: Single region outage, SLA violation
- **P2 - Medium**: Performance degradation
- **P3 - Low**: Non-critical issues

### Setup PagerDuty Integration

```bash
# Set your PagerDuty API token
export PAGERDUTY_API_TOKEN="your-api-token"

# Run integration setup
python monitoring/alerting/pagerduty-config.py
```

## 📋 Operational Procedures

### Daily Operations
- Morning health checks at 9:00 AM SGT
- Review overnight alerts and incidents
- Validate synthetic monitoring results
- Check cost and resource utilization

### Weekly Tasks
- Security assessment and access review
- Performance analysis and optimization
- Backup verification and testing
- Documentation and runbook updates

### Monthly Reviews
- Capacity planning and forecasting
- Disaster recovery testing
- Cost optimization analysis
- Team training and knowledge sharing

See [Operational Procedures](docs/operational-procedures.md) for detailed workflows.

## 🆘 Incident Response

The project includes comprehensive incident response procedures:

- **[Incident Response Runbook](docs/incident-response-runbook.md)**: Step-by-step procedures for common incidents
- **Emergency Contacts**: 24/7 on-call rotation
- **Escalation Matrix**: Clear escalation paths
- **Post-Incident Process**: Learning and improvement procedures

### Common Incident Types
- Single/Multi-region outages
- Database performance issues
- SLA violations
- Security incidents
- Network connectivity problems

## 💰 Cost Management

### Current Architecture Costs (Estimated)

| Region | EC2 | RDS | ALB | Total/Month |
|--------|-----|-----|-----|-------------|
| Singapore | $25 | $15 | $20 | $60 |
| Hong Kong | $25 | $15 | $20 | $60 |
| Australia | $25 | $15 | $20 | $60 |
| UK | $25 | $15 | $20 | $60 |
| **Total** | **$100** | **$60** | **$80** | **$240** |

*Monitoring stack runs locally to minimize costs during demonstration*

### Cost Optimization Features
- Auto Scaling based on demand
- Reserved Instance recommendations
- Resource tagging for cost allocation
- Automated cost alerts and reporting

## 🔒 Security & Compliance

### Security Features
- VPC with private/public subnets
- Security groups with least privilege
- Encrypted RDS instances
- IAM roles and policies
- CloudTrail logging
- GuardDuty threat detection

### Compliance Standards
- **Financial Services**: Sub-500ms response times
- **SLA**: 99.99% availability target
- **Data Protection**: Encrypted at rest and in transit
- **Audit Trail**: Complete logging and monitoring

## 🛠️ Development & Customization

### Project Structure

```
├── terraform/                 # Infrastructure as Code
│   ├── modules/               # Reusable Terraform modules
│   │   ├── vpc/              # VPC and networking
│   │   ├── compute/          # EC2, ALB, Auto Scaling
│   │   ├── database/         # RDS MySQL instances
│   │   └── cloudwatch/       # CloudWatch dashboards & alarms
│   └── environments/         # Region-specific configurations
│       ├── singapore/        # ap-southeast-1
│       ├── hongkong/         # ap-east-1
│       ├── australia/        # ap-southeast-2
│       └── uk/               # eu-west-2
├── monitoring/               # Monitoring stack configuration
│   ├── prometheus/           # Prometheus config and rules
│   ├── grafana/             # Grafana dashboards and provisioning
│   ├── alerting/            # AlertManager and PagerDuty config
│   └── blackbox/            # Blackbox exporter for health checks
├── scripts/                 # Automation and utility scripts
│   ├── deploy-infrastructure.sh  # Deployment automation
│   └── health-check-synthetic.py # Synthetic monitoring
├── docs/                    # Documentation
│   ├── incident-response-runbook.md
│   └── operational-procedures.md
└── docker-compose.yml       # Local monitoring stack
```

### Adding New Regions

1. Copy existing region configuration:
   ```bash
   cp -r terraform/environments/singapore terraform/environments/new-region
   ```

2. Update variables for new region:
   ```bash
   # Edit terraform/environments/new-region/variables.tf
   # Update region, CIDR blocks, and tags
   ```

3. Add to deployment script:
   ```bash
   # Edit scripts/deploy-infrastructure.sh
   # Add new region to REGIONS array
   ```

### Customizing Monitoring

1. **Add Custom Metrics**: Edit `monitoring/prometheus/prometheus.yml`
2. **Create Dashboards**: Import JSON files to `monitoring/grafana/dashboards/`
3. **Configure Alerts**: Update `monitoring/prometheus/rules/sleek-alerts.yml`
4. **Add Integrations**: Extend `monitoring/alerting/alertmanager.yml`

## 🧪 Testing

### Infrastructure Testing
```bash
# Plan deployment without applying
./scripts/deploy-infrastructure.sh plan

# Validate Terraform configurations
cd terraform/environments/singapore && terraform validate
```

### Monitoring Testing
```bash
# Test synthetic health checks
./scripts/health-check-synthetic.py --verbose

# Validate Prometheus configuration
promtool check config monitoring/prometheus/prometheus.yml

# Test alert rules
promtool check rules monitoring/prometheus/rules/*.yml
```

### Disaster Recovery Testing
```bash
# Simulate region failure (in staging environment)
./scripts/disaster-recovery-test.sh --region singapore --duration 30m
```

## 📚 Documentation

- **[Incident Response Runbook](docs/incident-response-runbook.md)**: Emergency procedures and troubleshooting
- **[Operational Procedures](docs/operational-procedures.md)**: Daily, weekly, and monthly operations
- **Terraform Documentation**: Infrastructure code documentation
- **API Documentation**: Health check and synthetic monitoring APIs

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support & Contact

### Emergency Contacts
- **On-Call Engineer**: Available 24/7 via PagerDuty
- **Infrastructure Team**: infrastructure@sleek.com
- **Security Team**: security@sleek.com

### Documentation & Resources
- **Grafana Dashboards**: http://localhost:3000
- **Prometheus Metrics**: http://localhost:9090  
- **AlertManager**: http://localhost:9093
- **AWS Console**: https://console.aws.amazon.com

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏆 Key Achievements

This project demonstrates:

✅ **Multi-Region Architecture** - Production-ready infrastructure across 4 regions  
✅ **Financial Services Compliance** - 99.99% SLA with sub-500ms response times  
✅ **Comprehensive Monitoring** - Real-time metrics, alerting, and dashboards  
✅ **Incident Management** - Complete runbooks and escalation procedures  
✅ **Infrastructure as Code** - Fully automated deployment with Terraform  
✅ **Cost Optimization** - Resource monitoring and optimization strategies  
✅ **Security Best Practices** - Encryption, access control, and audit logging  
✅ **Operational Excellence** - Detailed procedures and knowledge management  

---

**Built with ❤️ for Sleek's multi-region operations**  
*Demonstrating enterprise-grade infrastructure monitoring and management*