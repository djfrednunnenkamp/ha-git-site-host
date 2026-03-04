#!/usr/bin/env python3
import hmac
import hashlib
import json
import os
import signal
from http.server import BaseHTTPRequestHandler, HTTPServer

CONFIG_PATH = "/data/options.json"
UPDATER_PID = int(os.environ.get("UPDATER_PID", "0"))

def load_options():
    with open(CONFIG_PATH, "r", encoding="utf-8") as f:
        return json.load(f)

class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        opts = load_options()
        secret = (opts.get("webhook_secret") or "").encode("utf-8")

        length = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(length)

        # GitHub signature header: X-Hub-Signature-256: sha256=...
        sig = self.headers.get("X-Hub-Signature-256", "")
        if not sig.startswith("sha256="):
            self.send_response(400)
            self.end_headers()
            self.wfile.write(b"Missing or invalid signature header")
            return

        expected = "sha256=" + hmac.new(secret, body, hashlib.sha256).hexdigest()
        if not hmac.compare_digest(expected, sig):
            self.send_response(401)
            self.end_headers()
            self.wfile.write(b"Invalid signature")
            return

        # OK, trigger updater immediately
        if UPDATER_PID > 0:
            try:
                os.kill(UPDATER_PID, signal.SIGUSR1)
            except Exception:
                pass

        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"OK")

    def log_message(self, fmt, *args):
        # quiet logs
        return

if __name__ == "__main__":
    import signal

    opts = load_options()
    port = int(opts.get("webhook_port", 8098))

    server = HTTPServer(("0.0.0.0", port), Handler)
    server.serve_forever()