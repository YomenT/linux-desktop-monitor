#!/usr/bin/env python3
"""
Desktop Monitor Server
A lightweight web server that provides system metrics and file transfer for the Ubuntu Touch Desktop Monitor app.

Usage:
    python3 desktop_monitor_server.py [--port 8080] [--token YOUR_SECRET] [--files-root /home/user]
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import subprocess
import argparse
import sys
import os
import urllib.parse
import base64
import mimetypes
from PIL import ImageGrab, Image
from io import BytesIO
import pyautogui

# Optional authentication token
AUTH_TOKEN = None
# Root directory for file operations (default to user's home)
FILES_ROOT = os.path.expanduser('~')

class MonitorHandler(BaseHTTPRequestHandler):
    def check_auth(self):
        """Check authentication if token is set"""
        if AUTH_TOKEN:
            auth_header = self.headers.get('Authorization')
            if not auth_header or auth_header != f'Bearer {AUTH_TOKEN}':
                self.send_response(401)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({'error': 'Unauthorized'}).encode())
                return False
        return True

    def do_GET(self):
        if not self.check_auth():
            return

        # Handle /metrics endpoint
        if self.path == '/metrics':
            self.handle_metrics()
        # Handle /shutdown endpoint
        elif self.path == '/shutdown':
            self.handle_shutdown()
        # Handle /files/list endpoint
        elif self.path.startswith('/files/list'):
            self.handle_list_files()
        # Handle /files/download endpoint
        elif self.path.startswith('/files/download'):
            self.handle_download_file()
        # Handle /desktop/screenshot endpoint
        elif self.path == '/desktop/screenshot':
            self.handle_screenshot()
        else:
            self.send_response(404)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'error': 'Not found'}).encode())
            return

    def do_POST(self):
        if not self.check_auth():
            return

        # Handle /files/upload endpoint
        if self.path.startswith('/files/upload'):
            self.handle_upload_file()
        # Handle /desktop/mouse endpoint
        elif self.path == '/desktop/mouse':
            self.handle_mouse_control()
        # Handle /desktop/keyboard endpoint
        elif self.path == '/desktop/keyboard':
            self.handle_keyboard_input()
        else:
            self.send_response(404)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'error': 'Not found'}).encode())

    def handle_metrics(self):
        try:
            # Gather system information
            data = {
                'success': True,
                'hostname': self.get_hostname(),
                'uptime': self.get_uptime(),
                'cpu': self.get_cpu_usage(),
                'ram': self.get_ram_usage(),
                'temperature': self.get_temperature()
            }

            # Send successful response
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps(data).encode())

        except Exception as e:
            # Send error response
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'error': str(e)}).encode())

    def handle_shutdown(self):
        """Handle shutdown request"""
        try:
            # Send success response first
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps({
                'success': True,
                'message': 'Shutdown command initiated'
            }).encode())

            # Schedule shutdown in 5 seconds (gives time for response to be sent)
            import threading
            def delayed_shutdown():
                import time
                time.sleep(2)
                subprocess.run(['shutdown', '-h', 'now'], check=False)
            
            shutdown_thread = threading.Thread(target=delayed_shutdown)
            shutdown_thread.daemon = True
            shutdown_thread.start()

        except Exception as e:
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'error': str(e)}).encode())

    def handle_list_files(self):
        """List files in a directory"""
        try:
            # Parse query parameters
            query = urllib.parse.urlparse(self.path).query
            params = urllib.parse.parse_qs(query)
            path = params.get('path', [''])[0]
            
            # Sanitize and resolve path
            if not path or path == '/':
                target_path = FILES_ROOT
            else:
                # Remove leading slash and join with FILES_ROOT
                clean_path = path.lstrip('/')
                target_path = os.path.normpath(os.path.join(FILES_ROOT, clean_path))
            
            # Security check: ensure path is within FILES_ROOT
            if not target_path.startswith(FILES_ROOT):
                self.send_response(403)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({'error': 'Access denied'}).encode())
                return
            
            # Check if path exists
            if not os.path.exists(target_path):
                self.send_response(404)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({'error': 'Path not found'}).encode())
                return
            
            # List directory contents
            items = []
            if os.path.isdir(target_path):
                for item in sorted(os.listdir(target_path)):
                    item_path = os.path.join(target_path, item)
                    try:
                        stat = os.stat(item_path)
                        is_dir = os.path.isdir(item_path)
                        items.append({
                            'name': item,
                            'is_dir': is_dir,
                            'size': stat.st_size if not is_dir else 0,
                            'modified': int(stat.st_mtime)
                        })
                    except:
                        # Skip items we can't access
                        continue
            
            # Get relative path from FILES_ROOT
            if target_path == FILES_ROOT:
                rel_path = '/'
            else:
                rel_path = '/' + os.path.relpath(target_path, FILES_ROOT)
            
            # Get parent path
            parent_path = None
            if target_path != FILES_ROOT:
                parent = os.path.dirname(target_path)
                if parent.startswith(FILES_ROOT):
                    parent_path = '/' + os.path.relpath(parent, FILES_ROOT) if parent != FILES_ROOT else '/'
            
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps({
                'success': True,
                'path': rel_path,
                'parent': parent_path,
                'items': items
            }).encode())
            
        except Exception as e:
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'error': str(e)}).encode())

    def handle_download_file(self):
        """Download a file from desktop"""
        try:
            # Parse query parameters
            query = urllib.parse.urlparse(self.path).query
            params = urllib.parse.parse_qs(query)
            path = params.get('path', [''])[0]
            
            if not path:
                self.send_response(400)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({'error': 'No path specified'}).encode())
                return
            
            # Sanitize and resolve path
            clean_path = path.lstrip('/')
            target_path = os.path.normpath(os.path.join(FILES_ROOT, clean_path))
            
            # Security check
            if not target_path.startswith(FILES_ROOT):
                self.send_response(403)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({'error': 'Access denied'}).encode())
                return
            
            # Check if file exists and is a file
            if not os.path.exists(target_path) or not os.path.isfile(target_path):
                self.send_response(404)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({'error': 'File not found'}).encode())
                return
            
            # Read file and encode as base64
            with open(target_path, 'rb') as f:
                file_data = f.read()
                file_base64 = base64.b64encode(file_data).decode('utf-8')
            
            # Get mime type
            mime_type, _ = mimetypes.guess_type(target_path)
            
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps({
                'success': True,
                'filename': os.path.basename(target_path),
                'size': len(file_data),
                'mime_type': mime_type or 'application/octet-stream',
                'data': file_base64
            }).encode())
            
        except Exception as e:
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'error': str(e)}).encode())

    def handle_upload_file(self):
        """Upload a file to desktop"""
        try:
            # Parse query parameters for target path
            query = urllib.parse.urlparse(self.path).query
            params = urllib.parse.parse_qs(query)
            path = params.get('path', [''])[0]
            
            # Read request body
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length)
            
            # Parse JSON body
            data = json.loads(body.decode('utf-8'))
            filename = data.get('filename')
            file_base64 = data.get('data')
            
            if not filename or not file_base64:
                self.send_response(400)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({'error': 'Missing filename or data'}).encode())
                return
            
            # Sanitize filename
            filename = os.path.basename(filename)
            
            # Determine target directory
            if not path or path == '/':
                target_dir = FILES_ROOT
            else:
                clean_path = path.lstrip('/')
                target_dir = os.path.normpath(os.path.join(FILES_ROOT, clean_path))
            
            # Security check
            if not target_dir.startswith(FILES_ROOT):
                self.send_response(403)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({'error': 'Access denied'}).encode())
                return
            
            # Create directory if it doesn't exist
            os.makedirs(target_dir, exist_ok=True)
            
            # Write file
            target_path = os.path.join(target_dir, filename)
            file_data = base64.b64decode(file_base64)
            
            with open(target_path, 'wb') as f:
                f.write(file_data)
            
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps({
                'success': True,
                'message': 'File uploaded successfully',
                'path': os.path.relpath(target_path, FILES_ROOT),
                'size': len(file_data)
            }).encode())
            
        except Exception as e:
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'error': str(e)}).encode())

    def handle_screenshot(self):
        """Capture desktop screenshot and return as base64-encoded JPEG"""
        try:
            # Capture the screen
            screenshot = ImageGrab.grab()
            
            # Store original desktop dimensions
            original_width = screenshot.width
            original_height = screenshot.height
            
            # Convert to JPEG for better compression
            buffer = BytesIO()
            # Resize to reduce bandwidth (adjust quality/size as needed)
            # You can make this configurable via query parameters later
            screenshot.thumbnail((1280, 720), Image.Resampling.LANCZOS)
            screenshot.save(buffer, format='JPEG', quality=75, optimize=True)
            
            # Encode as base64
            screenshot_base64 = base64.b64encode(buffer.getvalue()).decode('utf-8')
            
            # Send response
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps({
                'success': True,
                'image': screenshot_base64,
                'format': 'jpeg',
                'width': original_width,
                'height': original_height,
                'thumbnail_width': screenshot.width,
                'thumbnail_height': screenshot.height
            }).encode())
            
        except Exception as e:
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'error': str(e)}).encode())

    def handle_mouse_control(self):
        """Handle mouse control commands"""
        try:
            # Read request body
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length)
            data = json.loads(body.decode('utf-8'))
            
            action = data.get('action')
            x = data.get('x')
            y = data.get('y')
            button = data.get('button', 'left')  # left, right, middle
            
            if action == 'move':
                # Move mouse to absolute position
                pyautogui.moveTo(x, y, duration=0.1)
                message = f"Mouse moved to ({x}, {y})"
                
            elif action == 'click':
                # Click at specified position
                pyautogui.click(x, y, button=button)
                message = f"{button.capitalize()} clicked at ({x}, {y})"
                
            elif action == 'doubleclick':
                # Double click at specified position
                pyautogui.doubleClick(x, y)
                message = f"Double clicked at ({x}, {y})"
                
            elif action == 'scroll':
                # Scroll (y value is scroll amount)
                pyautogui.scroll(int(y))
                message = f"Scrolled {y} units"
                
            else:
                self.send_response(400)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({'error': 'Invalid action'}).encode())
                return
            
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps({
                'success': True,
                'message': message
            }).encode())
            
        except Exception as e:
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'error': str(e)}).encode())

    def handle_keyboard_input(self):
        """Handle keyboard input commands"""
        try:
            # Read request body
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length)
            data = json.loads(body.decode('utf-8'))
            
            text = data.get('text', '')
            key = data.get('key', '')
            
            if text:
                # Type text
                pyautogui.write(text, interval=0.05)
                message = f"Typed: {text}"
            elif key:
                # Press special key (enter, backspace, etc.)
                pyautogui.press(key)
                message = f"Pressed key: {key}"
            else:
                self.send_response(400)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({'error': 'No text or key specified'}).encode())
                return
            
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps({
                'success': True,
                'message': message
            }).encode())
            
        except Exception as e:
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'error': str(e)}).encode())

    def do_OPTIONS(self):
        # Handle CORS preflight
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Authorization, Content-Type')
        self.end_headers()

    def get_hostname(self):
        """Get system hostname"""
        try:
            result = subprocess.run(['hostname'], capture_output=True, text=True, timeout=2)
            return result.stdout.strip()
        except:
            return 'Unknown'

    def get_uptime(self):
        """Get system uptime"""
        try:
            result = subprocess.run(['uptime', '-p'], capture_output=True, text=True, timeout=2)
            uptime = result.stdout.strip()
            # Remove 'up ' prefix if present
            return uptime.replace('up ', '') if uptime.startswith('up ') else uptime
        except:
            # Fallback to reading /proc/uptime
            try:
                with open('/proc/uptime', 'r') as f:
                    uptime_seconds = int(float(f.readline().split()[0]))
                    days = uptime_seconds // 86400
                    hours = (uptime_seconds % 86400) // 3600
                    minutes = (uptime_seconds % 3600) // 60
                    return f"{days}d {hours}h {minutes}m"
            except:
                return 'Unknown'

    def get_cpu_usage(self):
        """Get current CPU usage percentage"""
        try:
            # Use top to get CPU usage
            result = subprocess.run(
                ['top', '-bn1'], 
                capture_output=True, 
                text=True, 
                timeout=3
            )
            for line in result.stdout.split('\n'):
                if 'Cpu(s)' in line:
                    # Extract idle percentage and calculate usage
                    parts = line.split(',')
                    for part in parts:
                        if 'id' in part:
                            idle = float(part.split()[0])
                            return str(round(100 - idle, 1))
            return '0'
        except:
            return '0'

    def get_ram_usage(self):
        """Get RAM usage in human-readable format"""
        try:
            result = subprocess.run(
                ['free', '-h'], 
                capture_output=True, 
                text=True, 
                timeout=2
            )
            for line in result.stdout.split('\n'):
                if line.startswith('Mem:'):
                    parts = line.split()
                    total = parts[1]
                    used = parts[2]
                    return f"{used}/{total}"
            return 'Unknown'
        except:
            return 'Unknown'

    def get_temperature(self):
        """Get CPU temperature if available"""
        try:
            # Try sensors command first
            result = subprocess.run(
                ['sensors'], 
                capture_output=True, 
                text=True, 
                timeout=2
            )
            for line in result.stdout.split('\n'):
                # Support Intel (Core/Package), AMD (Tctl/Tccd), and generic temp labels
                if any(label in line for label in ['Core 0', 'Package id 0', 'Tctl:', 'Tccd1:', 'CPU:', 'temp1:']):
                    # Extract temperature
                    for part in line.split():
                        if '°C' in part:
                            temp = part.replace('+', '').replace('°C', '')
                            try:
                                float(temp)  # Validate it's a number
                                return temp + '°C'
                            except:
                                continue
        except:
            pass

        # Try reading from thermal zones
        try:
            import os
            thermal_path = '/sys/class/thermal'
            if os.path.exists(thermal_path):
                for i in range(10):  # Check first 10 thermal zones
                    zone_file = f'{thermal_path}/thermal_zone{i}/temp'
                    if os.path.exists(zone_file):
                        with open(zone_file, 'r') as f:
                            temp_milli = int(f.read().strip())
                            temp_celsius = temp_milli / 1000
                            # Only return if temperature is reasonable (0-150°C)
                            if 0 < temp_celsius < 150:
                                return f"{temp_celsius:.1f}°C"
        except:
            pass

        return 'N/A'

    def log_message(self, format, *args):
        """Override to customize logging"""
        print(f"[{self.log_date_time_string()}] {format % args}")


def main():
    parser = argparse.ArgumentParser(description='Desktop Monitor Server for Ubuntu Touch')
    parser.add_argument('--port', type=int, default=8080, help='Port to listen on (default: 8080)')
    parser.add_argument('--token', type=str, help='Optional authentication token')
    parser.add_argument('--host', type=str, default='0.0.0.0', help='Host to bind to (default: 0.0.0.0)')
    parser.add_argument('--files-root', type=str, help='Root directory for file operations (default: user home)')
    
    args = parser.parse_args()

    global AUTH_TOKEN, FILES_ROOT
    AUTH_TOKEN = args.token
    if args.files_root:
        FILES_ROOT = os.path.abspath(os.path.expanduser(args.files_root))

    server_address = (args.host, args.port)
    httpd = HTTPServer(server_address, MonitorHandler)

    print("=" * 60)
    print("Desktop Monitor Server")
    print("=" * 60)
    print(f"Server running on http://{args.host}:{args.port}")
    print(f"Metrics endpoint: http://YOUR_IP:{args.port}/metrics")
    print(f"File browser root: {FILES_ROOT}")
    if AUTH_TOKEN:
        print(f"Authentication: Enabled (token: {AUTH_TOKEN})")
    else:
        print("Authentication: Disabled (anyone on network can access)")
    print("\nPress Ctrl+C to stop the server")
    print("=" * 60)

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n\nShutting down server...")
        httpd.shutdown()
        sys.exit(0)


if __name__ == '__main__':
    main()
