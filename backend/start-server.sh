#!/bin/bash

# Start Rails server bound to all interfaces (0.0.0.0)
# This allows connections from mobile devices and emulators on the network

cd "$(dirname "$0")"

echo "Starting Rails server on http://0.0.0.0:3000"
echo "This allows connections from mobile devices on your network"
echo ""
echo "To find your local IP address:"
echo "  macOS/Linux: ifconfig | grep 'inet ' | grep -v 127.0.0.1"
echo "  Windows: ipconfig"
echo ""
echo "Update mobile/src/services/api.ts with your IP address"
echo ""

rails server -b 0.0.0.0

