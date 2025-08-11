#!/usr/bin/env python3
"""
Simple static file server for the Homie test client
Serves files from the test_client directory on http://localhost:3000
"""

import http.server
import socketserver
import os
import pathlib
import threading

try:
    import requests
except Exception:
    requests = None

PORT = 3000


def run_server():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(base_dir)

    # Ensure vendor assets are available (download Socket.IO client if missing)
    try:
        vendor_dir = pathlib.Path(base_dir) / "vendor"
        vendor_dir.mkdir(parents=True, exist_ok=True)
        sio_local = vendor_dir / "socket.io.min.js"
        if not sio_local.exists() and requests is not None:
            url = "https://cdn.socket.io/4.7.2/socket.io.min.js"
            print(f"Fetching Socket.IO client from {url} ...")
            try:
                resp = requests.get(url, timeout=10)
                resp.raise_for_status()
                sio_local.write_bytes(resp.content)
                print("Saved vendor/socket.io.min.js")
            except Exception as e:
                print(f"Warning: could not fetch Socket.IO client: {e}")
    except Exception as e:
        print(f"Vendor setup warning: {e}")
    handler = http.server.SimpleHTTPRequestHandler
    with socketserver.TCPServer(("0.0.0.0", PORT), handler) as httpd:
        print(f"Serving test client at http://localhost:{PORT}")
        print("Press Ctrl+C to stop")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            pass
        finally:
            httpd.server_close()


if __name__ == "__main__":
    run_server()


