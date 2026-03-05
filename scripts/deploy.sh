#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Node.js AWS Deployment Script${NC}"
echo -e "${GREEN}========================================${NC}"

# Check prerequisites
echo -e "\n${YELLOW}Checking prerequisites...${NC}"

command -v terraform >/dev/null 2>&1 || { echo -e "${RED}Error: terraform is required but not installed.${NC}" >&2; exit 1; }
command -v ansible >/dev/null 2>&1 || { echo -e "${RED}Error: ansible is required but not installed.${NC}" >&2; exit 1; }
command -v aws >/dev/null 2>&1 || { echo -e "${RED}Error: AWS CLI is required but not installed.${NC}" >&2; exit 1; }

echo -e "${GREEN}✓ All prerequisites met${NC}"

# Check AWS credentials
echo -e "\n${YELLOW}Checking AWS credentials...${NC}"
aws sts get-caller-identity >/dev/null 2>&1 || { echo -e "${RED}Error: AWS credentials not configured.${NC}" >&2; exit 1; }
echo -e "${GREEN}✓ AWS credentials configured${NC}"

# Terraform deployment
echo -e "\n${YELLOW}========================================${NC}"
echo -e "${YELLOW}  Step 1: Deploying Infrastructure${NC}"
echo -e "${YELLOW}========================================${NC}"

cd terraform

echo -e "\n${YELLOW}Initializing Terraform...${NC}"
terraform init

echo -e "\n${YELLOW}Validating Terraform configuration...${NC}"
terraform validate

echo -e "\n${YELLOW}Planning Terraform deployment...${NC}"
terraform plan -out=tfplan

echo -e "\n${YELLOW}Applying Terraform configuration...${NC}"
read -p "Do you want to proceed with the deployment? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo -e "${RED}Deployment cancelled.${NC}"
    exit 0
fi

terraform apply tfplan

# Get outputs
echo -e "\n${YELLOW}Retrieving infrastructure outputs...${NC}"
ALB_DNS=$(terraform output -raw alb_dns_name)
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
RDS_ADDRESS=$(terraform output -raw rds_address)
DB_NAME=$(terraform output -raw db_name)

echo -e "${GREEN}✓ Infrastructure deployed successfully${NC}"
echo -e "${GREEN}Load Balancer URL: http://${ALB_DNS}${NC}"

cd ..

# Wait for instances to be ready
echo -e "\n${YELLOW}Waiting for EC2 instances to be ready (60 seconds)...${NC}"
sleep 60

# Ansible configuration
echo -e "\n${YELLOW}========================================${NC}"
echo -e "${YELLOW}  Step 2: Configuring Servers${NC}"
echo -e "${YELLOW}========================================${NC}"

cd ansible

# Refresh dynamic inventory
echo -e "\n${YELLOW}Refreshing dynamic inventory...${NC}"
ansible-inventory -i inventory/aws_ec2.yml --graph

# Test connectivity
echo -e "\n${YELLOW}Testing SSH connectivity...${NC}"
ansible all -i inventory/aws_ec2.yml -m ping

# Deploy application
echo -e "\n${YELLOW}Deploying application with Ansible...${NC}"
ansible-playbook -i inventory/aws_ec2.yml site.yml \
  -e "db_host=${RDS_ADDRESS}" \
  -e "db_name=${DB_NAME}" \
  -e "db_username=$(cd ../terraform && terraform output -raw db_username)" \
  -e "db_password=${DB_PASSWORD:-$(read -sp 'Enter database password: ' pwd; echo $pwd)}"

cd ..

# Final health check
echo -e "\n${YELLOW}========================================${NC}"
echo -e "${YELLOW}  Step 3: Verification${NC}"
echo -e "${YELLOW}========================================${NC}"

echo -e "\n${YELLOW}Waiting for application to start (30 seconds)...${NC}"
sleep 30

echo -e "\n${YELLOW}Performing health check...${NC}"
HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" http://${ALB_DNS}/health)

if [ "$HEALTH_CHECK" -eq 200 ]; then
    echo -e "${GREEN}✓ Application is healthy!${NC}"
else
    echo -e "${RED}✗ Health check failed (HTTP $HEALTH_CHECK)${NC}"
fi

# Display summary
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Application URL: http://${ALB_DNS}${NC}"
echo -e "${GREEN}Health Check: http://${ALB_DNS}/health${NC}"
echo -e "${GREEN}API Info: http://${ALB_DNS}/api/info${NC}"
echo -e "${GREEN}========================================${NC}"

# Save outputs to file
cat > deployment-info.txt <<EOF
Deployment Information
=====================
Deployment Time: $(date)
Load Balancer URL: http://${ALB_DNS}
RDS Endpoint: ${RDS_ENDPOINT}
Database Name: ${DB_NAME}

Health Check: http://${ALB_DNS}/health
API Endpoints:
  - GET  /health
  - GET  /health/db
  - GET  /api/info
  - GET  /api/users
  - POST /api/users

SSH to instances:
$(cd terraform && terraform output -json ssh_connection_commands | jq -r '.[]')
EOF

echo -e "\n${GREEN}Deployment info saved to deployment-info.txt${NC}"