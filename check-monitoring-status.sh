#!/bin/bash

echo "======================================"
echo "Monitoring Stack Status Check"
echo "======================================"
echo ""

echo "1. Service Health Status:"
echo "--------------------------"
prometheus_health=$(curl -s http://localhost:9090/-/healthy 2>/dev/null)
if [ "$prometheus_health" == "Prometheus Server is Healthy." ]; then
    echo "✅ Prometheus: Healthy"
else
    echo "❌ Prometheus: Unhealthy or not running"
fi

alertmanager_health=$(curl -s http://localhost:9093/-/healthy 2>/dev/null)
if [ "$alertmanager_health" == "OK" ]; then
    echo "✅ Alertmanager: Healthy"
else
    echo "❌ Alertmanager: Unhealthy or not running"
fi

grafana_health=$(curl -s http://localhost:3000/api/health 2>/dev/null | jq -r '.database' 2>/dev/null)
if [ "$grafana_health" == "ok" ]; then
    echo "✅ Grafana: Healthy"
else
    echo "❌ Grafana: Unhealthy or not running"
fi

webhook_health=$(curl -s http://localhost:8888/health 2>/dev/null | jq -r '.status' 2>/dev/null)
if [ "$webhook_health" == "healthy" ]; then
    echo "✅ Webhook Receiver: Healthy"
else
    echo "❌ Webhook Receiver: Not running"
fi

echo ""
echo "2. Monitoring Targets:"
echo "-----------------------"
targets=$(curl -s http://localhost:9090/api/v1/targets 2>/dev/null | jq '.data.activeTargets' 2>/dev/null)
if [ "$targets" != "null" ] && [ "$targets" != "" ]; then
    up_count=$(curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets | map(select(.health == "up")) | length')
    total_count=$(curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets | length')
    echo "Active Targets: $up_count/$total_count UP"
    
    echo ""
    echo "Target Details:"
    curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | "  - \(.labels.job): \(.labels.instance | split("/") | last) [\(.health)]"'
else
    echo "❌ No targets found"
fi

echo ""
echo "3. Active Alerts:"
echo "-----------------"
alerts=$(curl -s http://localhost:9093/api/v1/alerts 2>/dev/null | jq '.data' 2>/dev/null)
if [ "$alerts" != "null" ] && [ "$alerts" != "" ] && [ "$alerts" != "[]" ]; then
    alert_count=$(curl -s http://localhost:9093/api/v1/alerts | jq '.data | length')
    echo "Found $alert_count active alert(s):"
    curl -s http://localhost:9093/api/v1/alerts | jq -r '.data[] | "  - \(.labels.alertname) [\(.labels.severity)] - \(.status.state)"'
else
    echo "✅ No active alerts"
fi

echo ""
echo "4. Access URLs:"
echo "---------------"
echo "📊 Grafana Dashboard: http://localhost:3000 (admin/sleek-monitor-2024)"
echo "🔍 Prometheus: http://localhost:9090"
echo "🚨 Alertmanager: http://localhost:9093"
echo "🔌 Webhook Logs: tail -f webhook.log"

echo ""
echo "======================================"