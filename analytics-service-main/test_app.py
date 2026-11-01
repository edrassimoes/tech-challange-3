import os
from unittest.mock import patch


def test_health():
    os.environ["AWS_REGION"] = "us-east-1"
    os.environ["AWS_SQS_URL"] = "http://test"
    os.environ["AWS_DYNAMODB_TABLE"] = "test"

    with patch("threading.Thread"), patch("boto3.Session"):
        from app import app

    response = app.test_client().get("/health")

    assert response.status_code == 200
    assert response.get_json() == {"status": "ok"}
