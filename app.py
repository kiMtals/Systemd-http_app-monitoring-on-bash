#!/usr/bin/env python3

from http.server import BaseHTTPRequestHandler, HTTPServer

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type","text/plain; charset=utf-8")
        self.end_headers()
        self.wfile.write(b"Hello World!")

    # отключим лог, у нас потом свой будет
    def log_message(self, format, *args):
        return

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', 8080), Handler)
    print("Server started on port 8080")
    server.serve_forever()