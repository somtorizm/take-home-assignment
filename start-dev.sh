#!/bin/bash

# Start development servers for Rails + React Native app
# This script starts both the Rails backend and React Native Metro bundler

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting development servers...${NC}\n"

# Check if we're in the right directory
if [ ! -d "backend" ] || [ ! -d "mobile" ]; then
    echo "Error: Please run this script from the project root directory"
    exit 1
fi

# Function to start Rails server
start_backend() {
    echo -e "${GREEN}Starting Rails backend server...${NC}"
    cd backend
    if [ ! -f "tmp/pids/server.pid" ] || ! kill -0 $(cat tmp/pids/server.pid) 2>/dev/null; then
        bundle exec rails server -b 0.0.0.0 &
        echo "Rails server starting on http://0.0.0.0:3000 (accessible from network)"
    else
        echo "Rails server is already running"
    fi
    cd ..
}

# Function to start Metro bundler
start_metro() {
    echo -e "${GREEN}Starting React Native Metro bundler...${NC}"
    cd mobile
    npm start &
    echo "Metro bundler starting..."
    cd ..
}

# Start both servers
start_backend
sleep 2
start_metro

echo -e "\n${BLUE}Both servers are starting in the background.${NC}"
echo -e "${BLUE}To stop them, use: pkill -f 'rails server' and pkill -f 'react-native start'${NC}"
echo -e "\n${GREEN}Backend API: http://0.0.0.0:3000 (accessible from network)${NC}"
echo -e "${GREEN}Metro bundler: http://localhost:8081${NC}"
echo -e "\n${BLUE}Note: Update mobile/src/services/api.ts with your local IP address${NC}"
echo -e "${BLUE}Find your IP: ifconfig | grep 'inet ' | grep -v 127.0.0.1${NC}"

