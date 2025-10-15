#!/bin/bash
# Test script for SSH monitor
# Usage: ./test_ssh.sh <hostname> <username> <password> [port]

if [ $# -lt 3 ]; then
    echo "Usage: $0 <hostname> <username> <password> [port]"
    echo "Example: $0 192.168.1.100 myuser mypassword 22"
    exit 1
fi

echo "Testing SSH connection..."
python3 ssh_monitor.py "$1" "$2" "$3" "${4:-22}"
