import pytest
from backend.core.web_server import WebServer
import json

@pytest.fixture
def client():
    # The WebServer requires a 'components' dictionary upon initialization.
    # For the purpose of testing the simple /health endpoint, it can be empty.
    web_server = WebServer(components={})
    
    # Manually set up the app and its routes
    from flask import Flask
    web_server.app = Flask(__name__)
    web_server._setup_http_routes()

    with web_server.app.test_client() as client:
        yield client

def test_health_check_endpoint(client):
    """
    Tests the /health endpoint to ensure it returns a 200 OK status
    and the correct JSON response.
    """
    response = client.get('/health')
    assert response.status_code == 200
    expected_data = {"status": "ok"}
    assert json.loads(response.data) == expected_data
