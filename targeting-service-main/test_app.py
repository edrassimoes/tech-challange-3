import os
from unittest.mock import patch


def test_health():
    os.environ["DATABASE_URL"] = "postgres://test"
    os.environ["AUTH_SERVICE_URL"] = "http://test"

    with patch("psycopg2.pool.SimpleConnectionPool"):
        from app import app

    response = app.test_client().get("/health")

    assert response.status_code == 200
    assert response.get_json() == {"status": "ok"}
