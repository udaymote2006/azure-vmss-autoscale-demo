#!/bin/bash
# vmss-setup.sh - Install dependencies and start sample Flask app on Azure VMSS instances

echo "=== Starting custom script at $(date) ===" >> /var/log/vmss-setup.log

# Update system and install required packages
yum update -y
yum install -y epel-release
yum install -y python3 python3-pip

# Install Flask
pip3 install flask

# Create the sample application (inline so no need to download)
cat > /home/AzureDemo/sample_app.py << 'EOF'
from flask import Flask
import time
app = Flask(__name__)

@app.route('/')
def home():
    return "Hello from Hybrid Auto-Scaled App! Running on Azure VMSS Instance"

@app.route('/stress')
def stress():
    # Simulate CPU load for testing
    for _ in range(10000000):
        pass
    return "Stress test complete on Azure"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
EOF

# Make sure the app file is executable (not strictly needed but good practice)
chmod +x /home/AzureDemo/sample_app.py

# Start the Flask app in background with nohup
# nohup = ignore hangup signal (keeps running after script ends)
# &     = run in background
# >>    = append output to log
nohup python3 /home/AzureDemo/sample_app.py >> /var/log/flask-app.log 2>&1 &

echo "=== Flask app started successfully at $(date) ===" >> /var/log/vmss-setup.log
echo "App is listening on port 5000" >> /var/log/vmss-setup.log

# Optional: Show running processes for debugging
ps aux | grep python3 >> /var/log/vmss-setup.log