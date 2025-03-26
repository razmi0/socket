#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

lua index.lua $1 $2

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Server started ${NC}"
else
    echo -e "${RED}Server failed to start${NC}"
fi
