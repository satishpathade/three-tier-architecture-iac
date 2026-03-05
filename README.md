# Three-Tier AWS Infrastructure as Code

A complete infrastructure-as-code solution for deploying a three-tier application architecture on AWS using Terraform and Ansible.

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **AWS CLI** configured with credentials
3. **Terraform** (>= 1.0)
4. **Ansible** (>= 2.9)
5. **SSH Key Pair** created in AWS
6. **Node.js** (for local development)

## Architecture

- **VPC**: Multi-AZ setup with public, private, and database subnets
- **ALB**: Application Load Balancer for traffic distribution
- **EC2**: Auto-scaled instances running Node.js application
- **RDS**: PostgreSQL database (Multi-AZ capable)
- **Security**: Security groups, encrypted storage, IAM roles

## Architecture Overview

This project deploys a production-ready three-tier architecture with:

### Web/Load Balancing Tier
- Application Load Balancer (ALB) for traffic distribution
- Auto-scaling capabilities
- HTTPS support ready

### Application Tier
- EC2 instances in private subnets across multiple availability zones
- Node.js application runtime
- Nginx reverse proxy
- Auto-recovery with systemd

### Database Tier
- Amazon RDS (MySQL) in private subnets
- Multi-AZ deployment for high availability
- Automated backups and maintenance windows
- Encryption at rest

## Project Structure

```
.
├── terraform/              # Infrastructure as Code
│   ├── provider.tf        # AWS provider configuration
│   ├── vpc.tf             # VPC, subnets, NAT gateways
│   ├── security_groups.tf # Security group definitions
│   ├── alb.tf             # Load balancer configuration
│   ├── ec2.tf             # EC2 instances and IAM roles
│   ├── rds.tf             # RDS database configuration
│   ├── variables.tf       # Variable definitions
│   ├── outputs.tf         # Output definitions
│   └── terraform.tfvars   # Default values
├── ansible/               # Configuration Management
│   ├── site.yml           # Main playbook
│   ├── ansible.cfg        # Ansible configuration
│   ├── inventory/         # Dynamic AWS inventory
│   └── roles/             # Ansible roles
│       ├── common/        # Base system setup
│       ├── nginx/         # Reverse proxy setup
│       └── nodejs_app/    # Node.js application deployment
├── src/                   # Application source code
│   ├── app.js             # Express.js application
│   ├── package.json       # Node.js dependencies
│   └── .env.example       # Environment variables template
├── scripts/               # Automation scripts
│   ├── deploy.sh          # Deployment orchestration
│   └── destroy.sh         # Infrastructure teardown
├── .gitignore             # Git ignore rules
└── README.md              # This file
```

## Prerequisites

Before you begin, ensure you have:

- **AWS Account** with appropriate permissions
- **Terraform** >= 1.0 installed
- **Ansible** >= 2.10 installed
- **AWS CLI** >= 2.0 configured with credentials
- **Python** >= 3.8 (for Ansible)
- **SSH Key Pair** created in your AWS region

### Installation

```bash
# macOS with Homebrew
brew install terraform ansible awscli

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y terraform ansible awscli

# Windows (with WSL recommended)
# Use Windows Subsystem for Linux (WSL) and follow Linux instructions
```

## Configuration

### 1. Set AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, region, and output format
```

### 2. Update Terraform Variables

Edit `terraform/terraform.tfvars` with your desired configuration:

```hcl
aws_region         = "us-east-1"
environment         = "dev"
project_name        = "three-tier-app"
vpc_cidr            = "10.0.0.0/16"
instance_type       = "t3.medium"
db_instance_class   = "db.t3.micro"
db_name             = "appdb"
```

### 3. Configure ansible Inventory

The inventory is dynamically populated from AWS EC2 tags. Update filter in `ansible/inventory/aws_ec2.yml` if needed.

### 4. Set Environment Variables (Optional)

```bash
# Create .env file in src/ directory
cp src/.env.example src/.env
# Edit with your configuration
```

## Deployment

### Automated Deployment

Run the deployment script to orchestrate Terraform and Ansible:

```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh dev <db_password>

# Or follow interactive prompts
./scripts/deploy.sh
```

### Manual Deployment

#### 1. Initialize Terraform

```bash
cd terraform
terraform init
cd ..
```

#### 2. Plan Infrastructure

```bash
cd terraform
terraform plan -out=tfplan \
  -var="db_password=your_secure_password"
cd ..
```

#### 3. Apply Infrastructure

```bash
cd terraform
terraform apply tfplan
cd ..
```

#### 4. Configure Instances with Ansible

```bash
cd ansible
ansible-playbook -i inventory/aws_ec2.yml \
  -e "db_password=your_secure_password" \
  site.yml
cd ..
```

## Accessing the Application

After successful deployment:

1. Get the ALB DNS name:
```bash
cd terraform
terraform output alb_dns_name
cd ..
```

2. Access the application:
```bash
curl http://<ALB_DNS_NAME>/
```

### Available Endpoints

- `/` - JSON response with API info
- `/health` - Health check endpoint
- `/status` - Application status and uptime
- `/api/info` - Application and environment information

## Monitoring and Logging

### CloudWatch Logs

All EC2 instances have IAM permissions to write to CloudWatch. Logs are automatically collected from:
- `/var/log/nginx/access.log`
- `/var/log/nginx/error.log`
- `/var/log/nodejs-app/stdout.log`
- `/var/log/nodejs-app/stderr.log`

### View Logs

```bash
# List log groups
aws logs describe-log-groups

# View specific logs
aws logs tail /aws/ec2/three-tier-app --follow
```

## Security

### Security Best Practices Implemented

- ✅ VPC with private subnets for application and database tiers
- ✅ Security groups with least privilege access
- ✅ RDS encryption at rest
- ✅ SSH key-pair authentication (no passwords)
- ✅ Multi-AZ deployment for high availability
- ✅ IAM roles with minimal required permissions
- ✅ Secrets managed via environment variables

### Additional Security Measures

For production deployment:

1. Enable HTTPS:
```bash
# Update ALB listener to use HTTPS with ACM certificate
# Modify alb.tf and add SSL certificate
```

2. Enable VPC Flow Logs:
```bash
terraform apply -var="enable_flow_logs=true"
```

3. Enable AWS WAF for ALB:
```bash
# Add WAF association in alb.tf
```

## Scaling

### Horizontal Scaling

To scale the application tier:

```bash
# Update Terraform
terraform apply -var="instance_count=4"
```

### Vertical Scaling

To change instance type:

```bash
terraform apply -var="instance_type=t3.large"
```

## Maintenance

### Database Backups

Automated daily backups are stored in AWS:

```bash
# List backups
aws rds describe-db-snapshots --db-instance-identifier three-tier-app-db
```

### RDS Patching

Maintenance window is set to Monday 04:00-05:00 UTC. Update in `terraform/rds.tf` if needed.

## Costs

Estimated monthly costs (us-east-1):
- ALB: ~$16
- EC2 (2× t3.medium): ~$60
- RDS (1× db.t3.micro, Multi-AZ): ~$80
- Data transfer: ~$10

**Total: ~$166/month**

Costs may vary by region and usage patterns.

## Destroying Infrastructure

### Safe Teardown

```bash
chmod +x scripts/destroy.sh
./scripts/destroy.sh dev
```

### Manual Teardown

```bash
cd terraform
terraform destroy -var="db_password=dummy"
cd ..
```

**⚠️ WARNING**: This will delete all resources including the RDS database. Ensure backups are created first.

## Troubleshooting

### Common Issues

#### 1. Terraform State Lock

```bash
# If stuck in a lock
cd terraform
terraform force-unlock <LOCK_ID>
cd ..
```

#### 2. Ansible Connection Timeout

```bash
# Check security groups allow SSH (port 22)
# Verify EC2 instances are running
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running"
```

#### 3. Application Not Starting

```bash
# SSH into EC2 instance
ssh -i ~/.ssh/your-key.pem ubuntu@<INSTANCE_IP>

# Check service status
sudo systemctl status nodejs-app

# View logs
journalctl -u nodejs-app -n 50 -f
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Maintenance and Updates

### Update Ansible Roles

```bash
cd ansible
ansible-galaxy install -r requirements.yml
cd ..
```

### Update Terraform Providers

```bash
cd terraform
terraform init -upgrade
cd ..
```

### Application Updates

Deploy new application versions:

```bash
cd ansible
ansible-playbook -i inventory/aws_ec2.yml \
  -e "app_branch=v2.0" \
  -t nodejs \
  site.yml
cd ..
```

## Support and Documentation

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Ansible Documentation](https://docs.ansible.com/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

## License

This project is licensed under the MIT License - see LICENSE file for details.

## Author

Created as a reference implementation for AWS three-tier architecture deployments.

---

**Last Updated**: March 2026
