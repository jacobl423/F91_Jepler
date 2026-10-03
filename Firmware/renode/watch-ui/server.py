#!/usr/bin/env python3
"""Local watch viewer. Pixels and GPIO responses come from the Renode machine."""
import argparse
from collections import deque
import json
import os
from pathlib import Path
import re
import shutil
import socket
import struct
import subprocess
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import zlib

ROOT = Path(__file__).resolve().parents[3]
UI = Path(__file__).resolve().parent


def png_from_ppm(data):
    header, dimensions, maximum, pixels = data.split(b'\n', 3)
    width, height = map(int, dimensions.split())
    if header != b'P6' or maximum != b'255' or len(pixels) != width * height * 3:
        raise ValueError('Invalid display snapshot')
    def chunk(kind, body):
        return struct.pack('!I', len(body)) + kind + body + struct.pack('!I', zlib.crc32(kind + body) & 0xffffffff)
    rows = b''.join(b'\0' + pixels[i:i + width * 3] for i in range(0, len(pixels), width * 3))
    return (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('!IIBBBBB', width, height, 8, 2, 0, 0, 0))
            + chunk(b'IDAT', zlib.compress(rows)) + chunk(b'IEND', b''))


class Monitor:
    def __init__(self, port):
        self.socket = socket.create_connection(('127.0.0.1', port), timeout=10)
        self.socket.settimeout(20)
        self.receive()

    def receive(self):
        data = b''
        while True:
            part = self.socket.recv(65536)
            if not part:
                raise RuntimeError('Renode monitor disconnected')
            data += part
            # Ignore telnet negotiation and ANSI cursor/color sequences.
            clean = re.sub(rb'\xff[\xfb-\xfe].', b'', data)
            clean = re.sub(rb'\x1b\[[0-?]*[ -/]*[@-~]', b'', clean)
            if re.search(rb'\((?:monitor|nRF52840)\)\s*$', clean):
                result = clean.decode('utf-8', errors='replace')
                if 'There was an error' in result or 'Error E' in result:
                    raise RuntimeError(result.strip())
                return result

    def command(self, text):
        # AntShell treats CR and LF as separate submissions. CRLF can leave an
        # extra prompt queued and falsely report the next command as complete.
        self.socket.sendall(text.encode() + b'\r')
        return self.receive()


class Watch:
    def __init__(self, renode):
        self.bindings = json.loads((ROOT/'build/renode-app/buttons.json').read_text())
        self.lock = threading.Lock()
        self.desired = set()
        self.transitions = deque()
        self.applied = set()
        self.last_input = 0
        self.sequence = 0
        self.frame = b''
        self.error = ''
        self.stopped = threading.Event()
        self.out = ROOT/'build/renode'/('watch-' + time.strftime('%Y%m%d-%H%M%S') + '-' + str(os.getpid()))
        self.out.mkdir(parents=True)
        (self.out/'tmp').mkdir()
        (self.out/'renode.config').write_text('[general]\nhistory-path = ' + str(self.out/'history') + '\n')
        (self.out/'watch.resc').write_text(
            '$app_bin=@' + str(ROOT/'build/renode-app/app.signed.bin') + '\n'
            'include @' + str(ROOT/'Firmware/renode/f91_jepler.resc') + '\n'
            'sysbus.uart0 CreateFileBackend @' + str(self.out/'uart.log') + ' true\n')
        with socket.socket() as reserve:
            reserve.bind(('127.0.0.1', 0))
            port = reserve.getsockname()[1]
        env = os.environ.copy()
        env['TMPDIR'] = str(self.out/'tmp')
        self.log = (self.out/'renode.log').open('w')
        self.process = subprocess.Popen([renode, '--disable-gui', '-P', str(port), '-p',
            '--config', str(self.out/'renode.config'), str(self.out/'watch.resc')],
            cwd=ROOT, stdout=self.log, stderr=subprocess.STDOUT, env=env)
        self.port = port
        self.thread = threading.Thread(target=self.run, daemon=True)
        self.thread.start()

    def input(self, pressed):
        with self.lock:
            new_state = set(pressed)
            if new_state != self.desired:
                self.transitions.append(new_state)
                self.desired = new_state
            self.last_input = time.monotonic()

    def run(self):
        monitor = None
        try:
            deadline = time.monotonic() + 30
            while time.monotonic() < deadline and not self.stopped.is_set():
                try:
                    monitor = Monitor(self.port)
                    break
                except (ConnectionRefusedError, socket.timeout):
                    if self.process.poll() is not None:
                        raise RuntimeError('Renode exited; see renode.log')
                    time.sleep(0.1)
            if monitor is None:
                raise RuntimeError('Renode did not open its monitor')
            # Startup script executes asynchronously; wait for the machine prompt.
            deadline = time.monotonic() + 30
            while '(nRF52840)' not in monitor.command('mach'):
                if time.monotonic() > deadline:
                    raise RuntimeError('Renode machine did not load')
                time.sleep(0.1)
            for b in self.bindings:
                monitor.command(f"sysbus.{b['port']} OnGPIO {b['pin']} {str(b['active_low']).lower()}")
            monitor.command('emulation RunFor "2"')
            while not self.stopped.is_set():
                started = time.monotonic()
                with self.lock:
                    if started - self.last_input >= 1.5:
                        self.transitions.clear()
                        self.desired.clear()
                    # Preserve short taps even when down/up arrive within one frame.
                    desired = self.transitions.popleft() if self.transitions else self.desired.copy()
                for b in self.bindings:
                    key = b['key']
                    if (key in desired) != (key in self.applied):
                        high = (key not in desired) if b['active_low'] else (key in desired)
                        monitor.command(f"sysbus.{b['port']} OnGPIO {b['pin']} {str(high).lower()}")
                self.applied = desired
                monitor.command('emulation RunFor "0.05"')
                monitor.command('sysbus.twi0.display SaveFrame "' + str(self.out/'screen.ppm') + '"')
                frame = png_from_ppm((self.out/'screen.ppm').read_bytes())
                with self.lock:
                    self.frame = frame
                    self.sequence += 1
                self.stopped.wait(max(0, 0.05 - (time.monotonic() - started)))
        except Exception as error:
            self.error = str(error)
        finally:
            if monitor:
                monitor.socket.close()

    def state(self):
        uart = self.out/'uart.log'
        text = uart.read_text(errors='replace') if uart.exists() else ''
        with self.lock:
            return dict(ready=bool(self.frame) and not self.error, error=self.error,
                        frame=self.sequence, buttons=self.bindings, pressed=sorted(self.applied),
                        uart=text[-12000:], logs=str(self.out))

    def close(self):
        self.stopped.set()
        self.process.terminate()
        try:
            self.process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            self.process.kill()
            self.process.wait()
        self.thread.join(timeout=2)
        self.log.close()


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def respond(self, body, kind='application/json', status=200):
        if not isinstance(body, bytes):
            body = json.dumps(body).encode()
        self.send_response(status)
        self.send_header('Content-Type', kind)
        self.send_header('Content-Length', str(len(body)))
        self.send_header('Cache-Control', 'no-store')
        self.end_headers()
        try:
            self.wfile.write(body)
        except (BrokenPipeError, ConnectionResetError):
            pass

    def do_GET(self):
        path = self.path.split('?', 1)[0]
        if path == '/api/state':
            self.respond(self.server.watch.state())
        elif path == '/frame.png':
            with self.server.watch.lock:
                frame = self.server.watch.frame
            self.respond(frame, 'image/png', 200 if frame else 503)
        elif path in ('/', '/index.html'):
            self.respond((UI/'index.html').read_bytes(), 'text/html; charset=utf-8')
        else:
            self.respond({'error': 'Not found'}, status=404)

    def do_POST(self):
        # Only the local viewer may drive GPIOs. No cross-origin requests.
        if self.path != '/api/input' or self.headers.get('X-Watch-UI') != '1':
            self.respond({'error': 'Forbidden'}, status=403)
            return
        origin = self.headers.get('Origin')
        if origin and origin != 'http://' + self.headers.get('Host', ''):
            self.respond({'error': 'Forbidden'}, status=403)
            return
        try:
            length = int(self.headers.get('Content-Length', '0'))
            if not 0 < length < 1024:
                raise ValueError('Invalid input length')
            pressed = json.loads(self.rfile.read(length))['pressed']
            if not isinstance(pressed, list) or any(k not in ('1','2','3') for k in pressed):
                raise ValueError('Invalid keys')
            self.server.watch.input(pressed)
            self.respond({'ok': True})
        except (ValueError, KeyError, TypeError):
            self.respond({'error': 'Invalid button input'}, status=400)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', type=int, default=8085)
    args = parser.parse_args()
    renode = os.environ.get('RENODE') or shutil.which('renode') or '/Applications/Renode.app/Contents/MacOS/renode'
    for path in ('build/renode-app/app.signed.bin', 'build/renode-app/buttons.json', 'bin/mcuboot.elf'):
        if not (ROOT/path).exists():
            parser.error('Run bash Firmware/renode/build-display.sh first (missing ' + path + ')')
    server = ThreadingHTTPServer(('127.0.0.1', args.port), Handler)
    server.watch = Watch(renode)
    print(f'Watch viewer: http://127.0.0.1:{server.server_port}', flush=True)
    print(f'Logs: {server.watch.out}', flush=True)
    print('Press Ctrl+C to stop the viewer and its Renode process.', flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
        server.watch.close()


if __name__ == '__main__':
    main()
