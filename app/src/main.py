"""
SalesConnect API - Demo Flask Application
Deployed via ECS Fargate with Terraform
"""

import os
from datetime import datetime
from flask import Flask, jsonify, request

app = Flask(__name__)

# Configuration from environment
ENVIRONMENT = os.getenv("ENVIRONMENT", "development")
PORT = int(os.getenv("PORT", 8000))
VERSION = "1.0.0"


@app.route("/")
def root():
    """Root endpoint - API information"""
    return jsonify({
        "service": "salesconnect-api",
        "version": VERSION,
        "environment": ENVIRONMENT,
        "message": "Welcome to SalesConnect API - Deployed with Terraform + ECS",
        "endpoints": {
            "health": "/health",
            "info": "/info",
            "predict": "/predict (POST)"
        }
    })


@app.route("/health")
def health():
    """Health check endpoint for ALB"""
    return jsonify({
        "status": "healthy",
        "service": "salesconnect-api",
        "version": VERSION,
        "timestamp": datetime.utcnow().isoformat()
    })


@app.route("/info")
def info():
    """Detailed service information"""
    return jsonify({
        "service": "salesconnect-api",
        "version": VERSION,
        "environment": ENVIRONMENT,
        "runtime": {
            "python": os.popen("python --version").read().strip(),
            "port": PORT
        },
        "infrastructure": {
            "platform": "AWS ECS Fargate",
            "iac": "Terraform",
            "cicd": "GitHub Actions"
        },
        "author": "Leonard Palad",
        "portfolio": "ML Platform Engineer | DevOps"
    })


@app.route("/predict", methods=["POST"])
def predict():
    """
    Demo prediction endpoint
    Simulates an ML prediction for portfolio demonstration
    """
    try:
        data = request.get_json()

        if not data:
            return jsonify({
                "error": "No data provided",
                "usage": {
                    "method": "POST",
                    "content_type": "application/json",
                    "body": {
                        "customer_id": "string",
                        "tenure_months": "integer",
                        "monthly_charges": "float"
                    }
                }
            }), 400

        # Simulate prediction logic
        customer_id = data.get("customer_id", "unknown")
        tenure = data.get("tenure_months", 12)
        charges = data.get("monthly_charges", 50.0)

        # Simple mock churn prediction logic
        churn_probability = min(0.95, max(0.05, (charges / 100) - (tenure / 100)))
        risk_level = "high" if churn_probability > 0.7 else "medium" if churn_probability > 0.4 else "low"

        return jsonify({
            "prediction": {
                "customer_id": customer_id,
                "churn_probability": round(churn_probability, 3),
                "risk_level": risk_level,
                "recommendation": "Engage with retention offer" if risk_level == "high" else "Monitor customer"
            },
            "model": {
                "name": "churn-predictor-v1",
                "type": "demo",
                "note": "This is a simulated prediction for demonstration purposes"
            },
            "timestamp": datetime.utcnow().isoformat()
        })

    except Exception as e:
        return jsonify({
            "error": str(e),
            "status": "prediction_failed"
        }), 500


@app.errorhandler(404)
def not_found(e):
    """Handle 404 errors"""
    return jsonify({
        "error": "Endpoint not found",
        "available_endpoints": ["/", "/health", "/info", "/predict"]
    }), 404


@app.errorhandler(500)
def server_error(e):
    """Handle 500 errors"""
    return jsonify({
        "error": "Internal server error",
        "message": str(e)
    }), 500


if __name__ == "__main__":
    print(f"Starting SalesConnect API v{VERSION}")
    print(f"Environment: {ENVIRONMENT}")
    print(f"Port: {PORT}")
    app.run(host="0.0.0.0", port=PORT, debug=(ENVIRONMENT == "development"))
