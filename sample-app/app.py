from flask import Flask, jsonify
import os
import sys

app = Flask(__name__)

# Porta configurável via variável de ambiente
PORT = int(os.environ.get('PORT', 5000))
VERSION = os.environ.get('APP_VERSION', '1.0.0')

@app.route('/')
def home():
    return jsonify({
        'message': 'Hello from Sample App!',
        'version': VERSION,
        'port': PORT,
        'python_version': sys.version
    })

@app.route('/health')
def health():
    return jsonify({
        'status': 'healthy',
        'version': VERSION
    }), 200

@app.route('/info')
def info():
    return jsonify({
        'app_name': 'sample-app',
        'version': VERSION,
        'environment': os.environ.get('ENVIRONMENT', 'development'),
        'port': PORT
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=PORT, debug=False)