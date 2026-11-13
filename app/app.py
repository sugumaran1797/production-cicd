import os
import socket
from flask import Flask, Response, jsonify
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST

app = Flask(__name__)

# Prometheus Metrics
HTTP_REQUESTS_TOTAL = Counter(
    'http_requests_total',
    'Total count of HTTP requests processed',
    ['method', 'endpoint', 'http_status']
)

REQUEST_DURATION_SECONDS = Histogram(
    'http_request_duration_seconds',
    'Histogram of request processing duration in seconds',
    ['endpoint']
)

@app.route('/')
def home():
    endpoint = '/'
    with REQUEST_DURATION_SECONDS.labels(endpoint=endpoint).time():
        hostname = socket.gethostname()
        version = os.getenv("APP_VERSION", "v1.0.1")
        HTTP_REQUESTS_TOTAL.labels(method='GET', endpoint=endpoint, http_status='200').inc()
        return jsonify({
            "status": "healthy",
            "version": version,
            "pod_host": hostname,
            "message": "Production CI/CD Application Live"
        }), 200

@app.route('/healthz')
def healthz():
    return "OK", 200

@app.route('/metrics')
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
