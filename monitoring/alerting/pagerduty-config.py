#!/usr/bin/env python3
"""
PagerDuty Integration Configuration for Sleek Multi-Region Monitoring
Handles escalation policies, incident management, and on-call scheduling
"""

import requests
import json
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional
import os
from dataclasses import dataclass

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@dataclass
class EscalationPolicy:
    name: str
    description: str
    num_loops: int
    escalation_rules: List[Dict]

@dataclass
class Service:
    name: str
    description: str
    escalation_policy_id: str
    alert_creation: str = "create_alerts_and_incidents"

class PagerDutyIntegration:
    def __init__(self, api_token: str):
        self.api_token = api_token
        self.base_url = "https://api.pagerduty.com"
        self.headers = {
            "Authorization": f"Token token={api_token}",
            "Content-Type": "application/json",
            "Accept": "application/vnd.pagerduty+json;version=2"
        }
    
    def create_user(self, name: str, email: str, role: str = "user") -> Optional[str]:
        """Create a PagerDuty user"""
        user_data = {
            "user": {
                "name": name,
                "email": email,
                "role": role,
                "time_zone": "UTC"
            }
        }
        
        try:
            response = requests.post(
                f"{self.base_url}/users",
                headers=self.headers,
                json=user_data
            )
            
            if response.status_code == 201:
                user_id = response.json()["user"]["id"]
                logger.info(f"Created user {name} with ID: {user_id}")
                return user_id
            else:
                logger.error(f"Failed to create user {name}: {response.text}")
                return None
                
        except Exception as e:
            logger.error(f"Error creating user {name}: {e}")
            return None
    
    def create_schedule(self, name: str, time_zone: str = "UTC") -> Optional[str]:
        """Create an on-call schedule"""
        schedule_data = {
            "schedule": {
                "name": name,
                "time_zone": time_zone,
                "description": f"On-call schedule for {name}"
            }
        }
        
        try:
            response = requests.post(
                f"{self.base_url}/schedules",
                headers=self.headers,
                json=schedule_data
            )
            
            if response.status_code == 201:
                schedule_id = response.json()["schedule"]["id"]
                logger.info(f"Created schedule {name} with ID: {schedule_id}")
                return schedule_id
            else:
                logger.error(f"Failed to create schedule {name}: {response.text}")
                return None
                
        except Exception as e:
            logger.error(f"Error creating schedule {name}: {e}")
            return None
    
    def create_escalation_policy(self, policy: EscalationPolicy) -> Optional[str]:
        """Create an escalation policy"""
        policy_data = {
            "escalation_policy": {
                "name": policy.name,
                "description": policy.description,
                "num_loops": policy.num_loops,
                "escalation_rules": policy.escalation_rules
            }
        }
        
        try:
            response = requests.post(
                f"{self.base_url}/escalation_policies",
                headers=self.headers,
                json=policy_data
            )
            
            if response.status_code == 201:
                policy_id = response.json()["escalation_policy"]["id"]
                logger.info(f"Created escalation policy {policy.name} with ID: {policy_id}")
                return policy_id
            else:
                logger.error(f"Failed to create escalation policy {policy.name}: {response.text}")
                return None
                
        except Exception as e:
            logger.error(f"Error creating escalation policy {policy.name}: {e}")
            return None
    
    def create_service(self, service: Service) -> Optional[str]:
        """Create a PagerDuty service"""
        service_data = {
            "service": {
                "name": service.name,
                "description": service.description,
                "escalation_policy": {
                    "id": service.escalation_policy_id,
                    "type": "escalation_policy_reference"
                },
                "alert_creation": service.alert_creation
            }
        }
        
        try:
            response = requests.post(
                f"{self.base_url}/services",
                headers=self.headers,
                json=service_data
            )
            
            if response.status_code == 201:
                service_id = response.json()["service"]["id"]
                integration_key = response.json()["service"]["integrations"][0]["integration_key"]
                logger.info(f"Created service {service.name} with ID: {service_id}")
                logger.info(f"Integration key: {integration_key}")
                return service_id, integration_key
            else:
                logger.error(f"Failed to create service {service.name}: {response.text}")
                return None
                
        except Exception as e:
            logger.error(f"Error creating service {service.name}: {e}")
            return None

def setup_sleek_pagerduty_integration():
    """Setup complete PagerDuty integration for Sleek monitoring"""
    
    # Get API token from environment variable
    api_token = os.getenv("PAGERDUTY_API_TOKEN")
    if not api_token:
        logger.error("PAGERDUTY_API_TOKEN environment variable not set")
        return False
    
    pd = PagerDutyIntegration(api_token)
    
    # Create team members (mock data for demo)
    team_members = [
        {"name": "Sarah Chen", "email": "sarah.chen@sleek.com", "role": "admin"},
        {"name": "Marcus Wong", "email": "marcus.wong@sleek.com", "role": "user"},
        {"name": "Priya Sharma", "email": "priya.sharma@sleek.com", "role": "user"},
        {"name": "James Mitchell", "email": "james.mitchell@sleek.com", "role": "user"}
    ]
    
    user_ids = {}
    for member in team_members:
        user_id = pd.create_user(member["name"], member["email"], member["role"])
        if user_id:
            user_ids[member["name"]] = user_id
    
    # Create schedules for different regions
    schedules = {
        "APAC Primary": pd.create_schedule("APAC Primary On-Call", "Asia/Singapore"),
        "EMEA Primary": pd.create_schedule("EMEA Primary On-Call", "Europe/London"),
        "Global Escalation": pd.create_schedule("Global Escalation", "UTC")
    }
    
    # Create escalation policies
    escalation_policies = {}
    
    # Critical Infrastructure Policy
    critical_policy = EscalationPolicy(
        name="Sleek Critical Infrastructure",
        description="Immediate response for critical infrastructure failures",
        num_loops=3,
        escalation_rules=[
            {
                "escalation_delay_in_minutes": 0,
                "targets": [
                    {"id": schedules["APAC Primary"], "type": "schedule_reference"},
                    {"id": schedules["EMEA Primary"], "type": "schedule_reference"}
                ]
            },
            {
                "escalation_delay_in_minutes": 5,
                "targets": [
                    {"id": schedules["Global Escalation"], "type": "schedule_reference"}
                ]
            },
            {
                "escalation_delay_in_minutes": 15,
                "targets": [
                    {"id": user_ids.get("Sarah Chen"), "type": "user_reference"}
                ] if "Sarah Chen" in user_ids else []
            }
        ]
    )
    
    critical_policy_id = pd.create_escalation_policy(critical_policy)
    if critical_policy_id:
        escalation_policies["critical"] = critical_policy_id
    
    # SLA Violation Policy
    sla_policy = EscalationPolicy(
        name="Sleek SLA Violation Response",
        description="Fast response for SLA violations affecting financial services compliance",
        num_loops=2,
        escalation_rules=[
            {
                "escalation_delay_in_minutes": 0,
                "targets": [
                    {"id": schedules["APAC Primary"], "type": "schedule_reference"}
                ]
            },
            {
                "escalation_delay_in_minutes": 2,
                "targets": [
                    {"id": schedules["Global Escalation"], "type": "schedule_reference"}
                ]
            }
        ]
    )
    
    sla_policy_id = pd.create_escalation_policy(sla_policy)
    if sla_policy_id:
        escalation_policies["sla"] = sla_policy_id
    
    # Disaster Recovery Policy
    disaster_policy = EscalationPolicy(
        name="Sleek Disaster Recovery",
        description="Emergency escalation for multi-region outages",
        num_loops=1,
        escalation_rules=[
            {
                "escalation_delay_in_minutes": 0,
                "targets": [
                    {"id": user_ids.get("Sarah Chen"), "type": "user_reference"},
                    {"id": user_ids.get("Marcus Wong"), "type": "user_reference"}
                ] if all(name in user_ids for name in ["Sarah Chen", "Marcus Wong"]) else []
            }
        ]
    )
    
    disaster_policy_id = pd.create_escalation_policy(disaster_policy)
    if disaster_policy_id:
        escalation_policies["disaster"] = disaster_policy_id
    
    # Create services with integration keys
    services = [
        Service(
            name="Sleek Infrastructure Critical",
            description="Critical infrastructure monitoring alerts",
            escalation_policy_id=escalation_policies.get("critical", ""),
        ),
        Service(
            name="Sleek SLA Monitoring",
            description="SLA violation and compliance monitoring",
            escalation_policy_id=escalation_policies.get("sla", ""),
        ),
        Service(
            name="Sleek Disaster Recovery",
            description="Multi-region outage and disaster recovery",
            escalation_policy_id=escalation_policies.get("disaster", ""),
        )
    ]
    
    integration_keys = {}
    for service in services:
        if service.escalation_policy_id:
            result = pd.create_service(service)
            if result:
                service_id, integration_key = result
                integration_keys[service.name] = integration_key
    
    # Generate configuration files
    generate_alertmanager_config(integration_keys)
    generate_integration_summary(integration_keys, escalation_policies)
    
    return True

def generate_alertmanager_config(integration_keys: Dict[str, str]):
    """Generate AlertManager configuration with PagerDuty integration keys"""
    
    config_template = f"""
# Updated AlertManager configuration with PagerDuty integration keys
# Replace YOUR_PAGERDUTY_INTEGRATION_KEY_* placeholders in alertmanager.yml with:

receivers:
  - name: 'pagerduty-critical'
    pagerduty_configs:
      - routing_key: '{integration_keys.get("Sleek Infrastructure Critical", "REPLACE_WITH_CRITICAL_KEY")}'
        description: 'Critical Alert: {{{{ range .Alerts }}}}{{{{ .Annotations.summary }}}}{{{{ end }}}}'
        details:
          firing: '{{{{ range .Alerts }}}}{{{{ .Annotations.description }}}}{{{{ end }}}}'
          region: '{{{{ range .Alerts }}}}{{{{ .Labels.region }}}}{{{{ end }}}}'
          service: '{{{{ range .Alerts }}}}{{{{ .Labels.service }}}}{{{{ end }}}}'

  - name: 'pagerduty-sla'
    pagerduty_configs:
      - routing_key: '{integration_keys.get("Sleek SLA Monitoring", "REPLACE_WITH_SLA_KEY")}'
        description: 'SLA Violation: {{{{ range .Alerts }}}}{{{{ .Annotations.summary }}}}{{{{ end }}}}'
        severity: 'critical'
        details:
          firing: '{{{{ range .Alerts }}}}{{{{ .Annotations.description }}}}{{{{ end }}}}'
          region: '{{{{ range .Alerts }}}}{{{{ .Labels.region }}}}{{{{ end }}}}'
          sla_target: '99.99%'

  - name: 'pagerduty-disaster'
    pagerduty_configs:
      - routing_key: '{integration_keys.get("Sleek Disaster Recovery", "REPLACE_WITH_DISASTER_KEY")}'
        description: 'DISASTER RECOVERY: {{{{ range .Alerts }}}}{{{{ .Annotations.summary }}}}{{{{ end }}}}'
        severity: 'critical'
        details:
          firing: '{{{{ range .Alerts }}}}{{{{ .Annotations.description }}}}{{{{ end }}}}'
          action_required: 'Immediate disaster recovery procedures required'
"""
    
    with open("pagerduty-alertmanager-config.yml", "w") as f:
        f.write(config_template)
    
    logger.info("Generated PagerDuty AlertManager configuration")

def generate_integration_summary(integration_keys: Dict[str, str], escalation_policies: Dict[str, str]):
    """Generate integration summary document"""
    
    summary = {
        "pagerduty_integration": {
            "setup_date": datetime.now().isoformat(),
            "services": {
                service_name: {
                    "integration_key": key,
                    "purpose": get_service_purpose(service_name)
                }
                for service_name, key in integration_keys.items()
            },
            "escalation_policies": escalation_policies,
            "configuration_notes": [
                "Replace integration keys in monitoring/alerting/alertmanager.yml",
                "Update Prometheus alert rules to include proper labels",
                "Configure on-call schedules in PagerDuty web interface",
                "Test escalation policies with synthetic alerts",
                "Set up notification preferences for team members"
            ]
        }
    }
    
    with open("pagerduty-integration-summary.json", "w") as f:
        json.dump(summary, f, indent=2)
    
    logger.info("Generated PagerDuty integration summary")

def get_service_purpose(service_name: str) -> str:
    """Get service purpose description"""
    purposes = {
        "Sleek Infrastructure Critical": "Handles critical infrastructure failures, instance outages, and service disruptions",
        "Sleek SLA Monitoring": "Monitors SLA violations and financial services compliance requirements",
        "Sleek Disaster Recovery": "Escalates multi-region outages requiring disaster recovery procedures"
    }
    return purposes.get(service_name, "General monitoring service")

if __name__ == "__main__":
    logger.info("Setting up PagerDuty integration for Sleek multi-region monitoring...")
    
    if setup_sleek_pagerduty_integration():
        logger.info("PagerDuty integration setup completed successfully!")
        print("\nNext steps:")
        print("1. Update monitoring/alerting/alertmanager.yml with the generated integration keys")
        print("2. Configure on-call schedules in the PagerDuty web interface")
        print("3. Test escalation policies with synthetic alerts")
        print("4. Review pagerduty-integration-summary.json for complete setup details")
    else:
        logger.error("PagerDuty integration setup failed")