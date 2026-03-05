#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}========================================${NC}"
echo -e "${RED}  Infrastructure Destruction Script${NC}"
echo -e "${RED}========================================${NC}"

echo -e "\n${YELLOW}WARNING: This will destroy all infrastructure!${NC}"
read -p "Are you absolutely sure you want to destroy everything? (type 'destroy' to confirm): " confirm

if [ "$confirm" != "destroy" ]; then
    echo -e "${GREEN}Destruction cancelled.${NC}"
    exit 0
fi

cd terraform

echo -e "\n${YELLOW}Destroying infrastructure...${NC}"
terraform destroy -auto-approve

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Infrastructure Destroyed${NC}"
echo -e "${GREEN}========================================${NC}"

cd ..

# Clean up
rm -f deployment-info.txt
echo -e "${GREEN}Cleanup complete.${NC}"