#!/usr/bin/env python3
from flask import Flask, request, jsonify
from datetime import datetime
import json

app = Flask(__name__)

@app.route('/critical', methods=['POST'])
def handle_critical():
    try:
        data = request.json
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        print(f"\n[{timestamp}] CRITICAL ALERT RECEIVED:")
        print(json.dumps(data, indent=2))
        
        if 'alerts' in data:
            for alert in data['alerts']:
                status = alert.get('status', 'unknown')
                labels = alert.get('labels', {})
                annotations = alert.get('annotations', {})
                
                print(f"\n  Alert: {labels.get('alertname', 'Unknown')}")
                print(f"  Status: {status}")
                print(f"  Severity: {labels.get('severity', 'unknown')}")
                print(f"  Instance: {labels.get('instance', 'unknown')}")
                print(f"  Description: {annotations.get('description', 'No description')}")
        
        return jsonify({"status": "received"}), 200
    except Exception as e:
        print(f"Error processing alert: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/warning', methods=['POST'])
def handle_warning():
    try:
        data = request.json
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        print(f"\n[{timestamp}] WARNING ALERT RECEIVED:")
        print(json.dumps(data, indent=2))
        return jsonify({"status": "received"}), 200
    except Exception as e:
        print(f"Error processing alert: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "healthy"}), 200

if __name__ == '__main__':
    print("Starting webhook receiver on port 8888...")
    app.run(host='0.0.0.0', port=8888, debug=True)