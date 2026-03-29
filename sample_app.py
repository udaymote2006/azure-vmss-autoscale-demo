#!/usr/bin/env python3
from flask import Flask
import time
app = Flask(__name__)

@app.route('/')
def home():
    return "Hello from Hybrid Auto-Scaled App! (Local or Azure)"

@app.route('/stress')
def stress():
    # Simulate CPU load
    for _ in range(10000000):
        pass
    return "Stress test complete"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)