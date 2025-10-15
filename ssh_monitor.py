#!/usr/bin/env python3
"""
SSH Desktop Monitor Script
Connects to a remote Linux desktop and retrieves system metrics
"""

import sys
import json
import subprocess
import shlex

def ssh_command(host, username, password, port, command):
    """
    Execute a command via SSH using sshpass (simpler than paramiko for basic use)
    """
    try:
        # Using sshpass to avoid paramiko dependency issues on Ubuntu Touch
        ssh_cmd = [
            'sshpass', '-p', password,
            'ssh', '-o', 'StrictHostKeyChecking=no',
            '-o', 'UserKnownHostsFile=/dev/null',
            '-p', str(port),
            f'{username}@{host}',
            command
        ]
        
        result = subprocess.run(
            ssh_cmd,
            capture_output=True,
            text=True,
            timeout=10
        )
        
        if result.returncode == 0:
            return result.stdout.strip()
        else:
            return None
            
    except Exception as e:
        print(json.dumps({"error": f"SSH command failed: {str(e)}"}))
        return None

def get_system_info(host, username, password, port=22):
    """
    Retrieve system information from remote host
    """
    try:
        # Get hostname
        hostname = ssh_command(host, username, password, port, 'hostname')
        if hostname is None:
            return {"error": "Failed to connect. Check credentials and network."}
        
        # Get uptime
        uptime = ssh_command(host, username, password, port, 'uptime -p')
        
        # Get CPU usage (1-minute average from top)
        cpu_cmd = "top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | cut -d'%' -f1"
        cpu = ssh_command(host, username, password, port, cpu_cmd)
        
        # Get RAM usage
        ram_cmd = "free -h | grep Mem | awk '{print $3 \"/\" $2 \" (\" int($3/$2 * 100) \"%)\" }'"
        ram = ssh_command(host, username, password, port, ram_cmd)
        
        # Get temperature (if available)
        temp_cmd = "sensors 2>/dev/null | grep -E 'Core 0|Package id 0' | head -1 | awk '{print $3}' || echo 'N/A'"
        temp = ssh_command(host, username, password, port, temp_cmd)
        
        return {
            "success": True,
            "hostname": hostname or "Unknown",
            "uptime": uptime or "Unknown",
            "cpu": cpu or "0",
            "ram": ram or "Unknown",
            "temperature": temp or "N/A"
        }
        
    except Exception as e:
        return {"error": str(e)}

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print(json.dumps({
            "error": "Usage: ssh_monitor.py <host> <username> <password> [port]"
        }))
        sys.exit(1)
    
    host = sys.argv[1]
    username = sys.argv[2]
    password = sys.argv[3]
    port = int(sys.argv[4]) if len(sys.argv) > 4 else 22
    
    result = get_system_info(host, username, password, port)
    print(json.dumps(result))
