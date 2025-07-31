#!/usr/bin/env python3
"""
Simple webhook server to receive and display AlertManager alerts
Run this to see alerts in the console during disaster recovery tests
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import sys
from datetime import datetime

class AlertWebhookHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        post_data = self.rfile.read(content_length)
        
        try:
            alert_data = json.loads(post_data.decode('utf-8'))
            self.process_alert(alert_data)
        except json.JSONDecodeError:
            print(f"❌ Failed to parse JSON alert data")
        
        # Send response
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(b'{"status": "ok"}')
    
    def process_alert(self, data):
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        endpoint = self.path
        
        print(f"\n{'='*60}")
        print(f"🚨 ALERT RECEIVED at {timestamp}")
        print(f"📍 Endpoint: {endpoint}")
        print(f"{'='*60}")
        
        if 'alerts' in data:
            for alert in data['alerts']:
                status = alert.get('status', 'unknown')
                labels = alert.get('labels', {})
                annotations = alert.get('annotations', {})
                
                # Format alert display
                alert_name = labels.get('alertname', 'Unknown Alert')
                severity = labels.get('severity', 'info')
                region = labels.get('region', 'unknown')
                service = labels.get('service', 'unknown')
                
                summary = annotations.get('summary', 'No summary')
                description = annotations.get('description', 'No description')
                
                # Color coding for severity
                if severity == 'critical':
                    severity_icon = "🔴 CRITICAL"
                elif severity == 'warning':
                    severity_icon = "🟡 WARNING"
                else:
                    severity_icon = f"ℹ️  {severity.upper()}"
                
                status_icon = "🔥 FIRING" if status == 'firing' else "✅ RESOLVED"
                
                print(f"{status_icon} {severity_icon}")
                print(f"📋 Alert: {alert_name}")
                print(f"🌍 Region: {region}")
                print(f"⚙️  Service: {service}")
                print(f"📝 Summary: {summary}")
                print(f"📄 Description: {description}")
                print(f"-" * 60)
        
        # Also print raw data for debugging
        if len(sys.argv) > 1 and sys.argv[1] == '--debug':
            print(f"🔍 Raw Alert Data:")
            print(json.dumps(data, indent=2))
        
        print(f"{'='*60}\n")
    
    def log_message(self, format, *args):
        # Suppress default HTTP server logs
        pass

def main():
    port = 8888
    server_address = ('', port)
    
    print(f"🎯 Starting Alert Webhook Server")
    print(f"📡 Listening on http://localhost:{port}")
    print(f"🔗 AlertManager should send alerts here")
    print(f"💡 Use --debug flag to see raw JSON data")
    print(f"⏹️  Press Ctrl+C to stop")
    print(f"{'='*60}")
    
    httpd = HTTPServer(server_address, AlertWebhookHandler)
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print(f"\n🛑 Alert webhook server stopped")
        httpd.server_close()

if __name__ == '__main__':
    main()