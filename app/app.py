from flask import Flask, send_from_directory, Response
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST

app = Flask(__name__)

REQUEST_COUNT = Counter("app_requests_total", "Total HTTP requests", ["endpoint"])

@app.route("/")
def home():
    REQUEST_COUNT.labels(endpoint="/").inc()
    return send_from_directory(".", "index.html")

@app.route("/healthz")
def health():
    REQUEST_COUNT.labels(endpoint="/healthz").inc()
    return {"status": "ok"}, 200

@app.route("/metrics")
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
