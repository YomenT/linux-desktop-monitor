#!/usr/bin/env python3
"""
Desktop Monitor Server
A lightweight web server that provides system metrics for the Ubuntu Touch Desktop Monitor app.

Usage:
    python3 desktop_monitor_server.py [--port 8080] [--token YOUR_SECRET]
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import subprocess
import argparse
import sys

# Optional authentication token
AUTH_TOKEN = None

class MonitorHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        # Check authentication if token is set
        if AUTH_TOKEN:
            auth_header = self.headers.get('Authorization')
            if not auth_header or auth_header != f'Bearer {AUTH_TOKEN}':
                self.send_response(401)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({'error': 'Unauthorized'}).encode())
                return

        # Only handle /metrics endpoint
        if self.path != '/metrics':
            self.send_response(404)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'error': 'Not found'}).encode())
            return

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

    def do_OPTIONS(self):
        # Handle CORS preflight
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
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
                if 'Core 0' in line or 'Package id 0' in line:
                    # Extract temperature
                    for part in line.split():
                        if '°C' in part or 'C' in part:
                            temp = part.replace('+', '').replace('°C', '').replace('C', '')
                            try:
                                float(temp)  # Validate it's a number
                                return temp + '°C'
                            except:
                                continue
        except:
            pass

        # Try reading from thermal zone
        try:
            with open('/sys/class/thermal/thermal_zone0/temp', 'r') as f:
                temp_milli = int(f.read().strip())
                temp_celsius = temp_milli / 1000
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
    
    args = parser.parse_args()

    global AUTH_TOKEN
    AUTH_TOKEN = args.token

    server_address = (args.host, args.port)
    httpd = HTTPServer(server_address, MonitorHandler)

    print("=" * 60)
    print("Desktop Monitor Server")
    print("=" * 60)
    print(f"Server running on http://{args.host}:{args.port}")
    print(f"Endpoint: http://YOUR_IP:{args.port}/metrics")
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
