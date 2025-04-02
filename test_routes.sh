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
    
    # Make a request that captures response, status code, and timing
    local output=$(curl -s -o /tmp/response_body -w "%{http_code}\n%{time_namelookup} %{time_connect} %{time_total}" -X $method "$url")
    
    # Extract status code (first line of output)
    local status_code=$(echo "$output" | head -n 1)
    
    # Extract timing information (second line)
    local timing=$(echo "$output" | tail -n 1)
    
    # Print response if not empty
    if [ -s /tmp/response_body ]; then
        cat /tmp/response_body
    fi
    
    # Print status code
    # echo -e "${BLUE}Status Code: $status_code${NC}"
    
    # Parse and print timing information
    read dns connect total <<< "$timing"

    # Convert to nanoseconds
    dns=$(echo "$dns * 1000000" | bc)
    connect=$(echo "$connect * 1000000" | bc)
    total=$(echo "$total * 1000000" | bc)

    # Slice last 3 characters using parameter expansion
    dns=${dns:0:${#dns}-6}
    connect=${connect:0:${#connect}-6}
    total=${total:0:${#total}-6}

    echo -e "\n${BLUE}Time:${NC}"
    echo -e "  DNS lookup: ${dns} ns"
    echo -e "  Connect:    ${connect} ns"
    echo -e "  Total:      ${total} ns"

    print_result "$method $url $status_code"
}


echo -e "${BLUE}Starting API tests...${NC}"
echo "====================="

# # Test GET :8080
make_request "GET" "http://localhost:8080"

# Test GET :8080/json
make_request "GET" "http://localhost:8080/json"

# Test GET :8080/json with query parameters
make_request "GET" "http://localhost:8080/query?foo=bar&baz=foo"

# Test GET :8080/chain
make_request "GET" "http://localhost:8080/chain"

# Test GET :8080/users/thomas/oui
make_request "GET" "http://localhost:8080/users/thomas/oui"

# Test GET :8080/users/:name/:id
make_request "GET" "http://localhost:8080/users/me/1"

# Test POST :8080/users
make_request "POST" "http://localhost:8080/users"

# Test POST :8080/users/:name/:id
make_request "POST" "http://localhost:8080/users/thomas/oui"


echo -e "\n${BLUE}All tests completed!${NC}"



#  GET (8)
# |    /                 : [ handler ]
# |    /chain            : [ middleware1, middleware2, handler ]
# |    /json             : [ handler ]
# |    /users/thomas/oui : [ handler ]
# |    /index.css        : [ handler ]
# |    /query            : [ handler ]
# |    /index.js         : [ handler ]
# |    /users/:name/:id  : [ handler ]
# POST (2)
# |    /users           : [ handler ]
# |    /users/:name/:id : [ handler ] 