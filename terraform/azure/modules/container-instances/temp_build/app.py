from flask import Flask, jsonify
import os
import socket
import datetime

app = Flask(__name__)

@app.route("/")
def hello():
    return """
    <h1>🐍 Python App Running!</h1>
    <p><strong>Status:</strong> ✅ Healthy</p>
    <p><strong>Environment:</strong> Azure Container Instances</p>
    <p><strong>Hostname:</strong> {}</p>
    <p><strong>Time:</strong> {}</p>
    <p><strong>Version:</strong> 1.0</p>
    <hr>
    <p><small>Built with Terraform + ACR + ACI</small></p>
    """.format(socket.gethostname(), datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

@app.route("/health")
def health():
    return jsonify({
        "status": "healthy",
        "service": "python-app",
        "version": "1.0",
        "timestamp": datetime.datetime.now().isoformat(),
        "hostname": socket.gethostname()
    })

@app.route("/info")
def info():
    return jsonify({
        "app": "Python Flask Application",
        "environment": os.getenv("ENV", "production"),
        "port": os.getenv("PORT", "8000"),
        "hostname": socket.gethostname(),
        "python_version": "3.11"
    })

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    print(f"🚀 Starting Flask app on port {port}")
    app.run(host="0.0.0.0", port=port, debug=False)
