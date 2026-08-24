"""One-shot binary mailbox for moving serialized Roblox instances between Studio places.

POST /<any-path>  -> stores the raw request body in memory under that path
GET  /<any-path>  -> returns the stored bytes (404 if nothing stored)

Run:  python asset_relay.py [port]   (default 8667, binds 127.0.0.1 only)
"""
import http.server
import sys

STORE = {}

class Handler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        STORE[self.path] = self.rfile.read(length)
        self.send_response(200)
        self.send_header("Content-Length", "2")
        self.end_headers()
        self.wfile.write(b"ok")
        print(f"stored {length} bytes at {self.path}", flush=True)

    def do_GET(self):
        body = STORE.get(self.path)
        if body is None:
            self.send_response(404)
            self.send_header("Content-Length", "0")
            self.end_headers()
            return
        self.send_response(200)
        self.send_header("Content-Type", "application/octet-stream")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)
        print(f"served {len(body)} bytes from {self.path}", flush=True)

    def log_message(self, fmt, *args):
        pass

port = int(sys.argv[1]) if len(sys.argv) > 1 else 8667
http.server.HTTPServer(("127.0.0.1", port), Handler).serve_forever()
