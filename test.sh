#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print test results
print_result() {
    if [ $? -eq 0 ]; then
        echo -e "\n${GREEN}✓ $1${NC}"
    else
        echo -e "\n${RED}✗ $1${NC}"
    fi
}

echo "Starting API tests..."
echo "====================="

# Test GET :8080
echo -e "\nTesting GET :8080"
curl -s -X GET http://localhost:8080
print_result "GET :8080"

# Test POST :8080
echo -e "\nTesting POST :8080"
curl -s -X POST http://localhost:8080
print_result "POST :8080"

# Test GET :8080/json
echo -e "\nTesting GET :8080/json"
curl -s -X GET http://localhost:8080/json
print_result "GET :8080/json"

# Test POST :8080/json
echo -e "\nTesting POST :8080/json"
curl -s -X POST http://localhost:8080/json
print_result "POST :8080/json"

# Test GET :8080/json with query parameters
echo -e "\nTesting GET :8080/json with query parameters"
curl -s -X GET "http://localhost:8080/json?foo=bar&baz=foo"
print_result "GET :8080/json with query parameters"

# Test GET :8080/html
echo -e "\nTesting GET :8080/html"
curl -s -X GET http://localhost:8080/html
print_result "GET :8080/html"

# Test POST :8080/html
echo -e "\nTesting POST :8080/html"
curl -s -X POST http://localhost:8080/html
print_result "POST :8080/html"

echo -e "\nAll tests completed!"
