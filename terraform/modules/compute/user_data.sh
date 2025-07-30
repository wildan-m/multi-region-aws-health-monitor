#!/bin/bash
yum update -y
yum install -y httpd wget

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Install Node Exporter for Prometheus
cd /opt
wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
tar xvfz node_exporter-1.6.1.linux-amd64.tar.gz
mv node_exporter-1.6.1.linux-amd64 node_exporter
rm node_exporter-1.6.1.linux-amd64.tar.gz

# Create node_exporter service
cat << 'EOF' > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=nobody
Group=nobody
Type=simple
ExecStart=/opt/node_exporter/node_exporter

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter

# Create a simple web application
cat << 'EOF' > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>Sleek Health Monitor - ${region}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 20px; }
        .status { padding: 20px; margin: 20px 0; border-radius: 5px; }
        .healthy { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .region { font-size: 24px; color: #e74c3c; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Sleek Infrastructure Monitor</h1>
            <div class="region">Region: ${region}</div>
        </div>
        <div class="status healthy">
            <h3>✅ System Status: Healthy</h3>
            <p>Last Check: <span id="timestamp"></span></p>
            <p>Uptime: <span id="uptime"></span></p>
            <p>Load Average: <span id="load"></span></p>
        </div>
    </div>
    <script>
        function updateMetrics() {
            document.getElementById('timestamp').textContent = new Date().toLocaleString();
            fetch('/metrics').then(r => r.text()).then(data => {
                console.log('Metrics updated');
            });
        }
        setInterval(updateMetrics, 30000);
        updateMetrics();
    </script>
</body>
</html>
EOF

# Health check endpoint
cat << 'EOF' > /var/www/html/health
OK
EOF

# Simple metrics endpoint
cat << 'EOF' > /var/www/html/metrics
# HELP sleek_app_requests_total Total number of requests
# TYPE sleek_app_requests_total counter
sleek_app_requests_total 1000

# HELP sleek_app_response_time_seconds Response time in seconds  
# TYPE sleek_app_response_time_seconds histogram
sleek_app_response_time_seconds_bucket{le="0.1"} 800
sleek_app_response_time_seconds_bucket{le="0.5"} 950
sleek_app_response_time_seconds_bucket{le="1.0"} 990
sleek_app_response_time_seconds_bucket{le="+Inf"} 1000
sleek_app_response_time_seconds_sum 120.5
sleek_app_response_time_seconds_count 1000
EOF

systemctl enable httpd
systemctl start httpd

# Configure CloudWatch agent
cat << 'EOF' > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
    "metrics": {
        "namespace": "Sleek/Application",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "diskio": {
                "measurement": [
                    "io_time"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s