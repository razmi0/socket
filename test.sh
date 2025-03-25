#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print test results
print_result() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NC}"
    else
        echo -e "${RED}✗ $1${NC}"
    fi
}

# Function to make request and show timing
make_request() {
    local method=$1
    local url=$2
    echo -e "\n${BLUE}Testing $method $url${NC}"
    
    # Store the response and timing in separate variables
    local response=$(curl -s -X $method "$url")
    local timing=$(curl -s -w "\n%{time_namelookup} %{time_connect} %{time_total}" -X $method "$url" | tail -n 1)
    
    # Print response if not empty
    if [ ! -z "$response" ]; then
        echo "$response"
    fi
    
    # Parse and print timing information
    read dns connect total <<< "$timing"

    # convert to milliseconds 
    dns=$(echo "$dns * 1000000" | bc)
    connect=$(echo "$connect * 1000000" | bc)
    total=$(echo "$total * 1000000" | bc)

    # Slice last 3 characters using parameter expansion
    dns=${dns:0:${#dns}-6}
    connect=${connect:0:${#connect}-6}
    total=${total:0:${#total}-6}

    echo -e "${BLUE}Time:${NC}"
    echo -e "  DNS lookup: ${dns} ns"
    echo -e "  Connect:    ${connect} ns"
    echo -e "  Total:      ${total} ns"
    
    print_result "$method $url"
}

echo -e "${BLUE}Starting API tests...${NC}"
echo "====================="

# # Test GET :8080
make_request "GET" "http://localhost:8080"

# # Test GET :8080/json
make_request "GET" "http://localhost:8080/json"

# Test GET :8080/json with query parameters
make_request "GET" "http://localhost:8080/json?foo=bar&baz=foo"

# Test GET :8080/json/:id/:name
make_request "GET" "http://localhost:8080/json/123/foo"

# Test GET :8080/json/forwhat/:param1
make_request "GET" "http://localhost:8080/json/forwhat/foo"

echo -e "\n${BLUE}All tests completed!${NC}"
