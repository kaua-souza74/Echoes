"""Loopback-only Flutter Web preview, including GoRouter path fallback."""
import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse

parser = argparse.ArgumentParser()
parser.add_argument('--port', type=int, default=18768)
parser.add_argument('--directory', type=Path, default=Path(__file__).resolve().parents[1] / 'flutter_app/build/web')
args = parser.parse_args()

class FlutterHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        path = urlparse(self.path).path
        target = Path(self.translate_path(path))
        if not target.exists() and not Path(path).suffix:
            self.path = '/index.html'
        super().do_GET()

    def end_headers(self):
        self.send_header('Cache-Control', 'no-store')
        super().end_headers()

server = ThreadingHTTPServer(('127.0.0.1', args.port), partial(FlutterHandler, directory=str(args.directory.resolve())))
print(f'ECHOES local preview on http://127.0.0.1:{args.port}/', flush=True)
server.serve_forever()
