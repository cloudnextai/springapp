#!/bin/bash

# AWS ECS/Fargate Setup Script for User CRUD App
# This script creates all necessary AWS resources for deployment

set -e

# Configuration
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPOSITORY="user-crud-app"
ECS_CLUSTER="user-crud-app-cluster"
ECS_SERVICE="user-crud-app-service"
TASK_FAMILY="user-crud-app-task"
CONTAINER_NAME="user-crud-app"
APP_PORT=8080
CPU=256
MEMORY=512
DESIRED_COUNT=1

echo "═══════════════════════════════════════════════════════════"
echo "AWS ECS/Fargate Setup for User CRUD App"
echo "═══════════════════════════════════════════════════════════"
echo "Region: $AWS_REGION"
echo "Account ID: $AWS_ACCOUNT_ID"
echo "ECR Repository: $ECR_REPOSITORY"
echo "ECS Cluster: $ECS_CLUSTER"
echo ""

# Step 1: Create ECR Repository
echo "📦 Creating ECR Repository..."
if aws ecr describe-repositories --repository-names $ECR_REPOSITORY --region $AWS_REGION 2>/dev/null; then
    echo "✅ ECR Repository already exists"
else
    aws ecr create-repository \
        --repository-name $ECR_REPOSITORY \
        --region $AWS_REGION \
        --image-tag-mutability MUTABLE \
        --image-scanning-configuration scanOnPush=true
    echo "✅ ECR Repository created"
fi

# Step 2: Create CloudWatch Log Group
echo ""
echo "📋 Creating CloudWatch Log Group..."
LOG_GROUP="/ecs/$ECR_REPOSITORY"
if aws logs describe-log-groups --log-group-name-prefix $LOG_GROUP --region $AWS_REGION 2>/dev/null | grep -q $LOG_GROUP; then
    echo "✅ Log Group already exists"
else
    aws logs create-log-group --log-group-name $LOG_GROUP --region $AWS_REGION
    aws logs put-retention-policy --log-group-name $LOG_GROUP --retention-in-days 30 --region $AWS_REGION
    echo "✅ Log Group created"
fi

# Step 3: Create IAM Roles
echo ""
echo "🔐 Creating IAM Roles..."

# Check if role exists
if aws iam get-role --role-name ecsTaskExecutionRole 2>/dev/null; then
    echo "✅ ecsTaskExecutionRole already exists"
else
    # Create trust relationship document
    cat > /tmp/ecs-task-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

    aws iam create-role \
        --role-name ecsTaskExecutionRole \
        --assume-role-policy-document file:///tmp/ecs-task-trust-policy.json
    
    aws iam attach-role-policy \
        --role-name ecsTaskExecutionRole \
        --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
    
    echo "✅ ecsTaskExecutionRole created"
fi

if aws iam get-role --role-name ecsTaskRole 2>/dev/null; then
    echo "✅ ecsTaskRole already exists"
else
    aws iam create-role \
        --role-name ecsTaskRole \
        --assume-role-policy-document file:///tmp/ecs-task-trust-policy.json
    
    echo "✅ ecsTaskRole created"
fi

# Step 4: Create ECS Cluster
echo ""
echo "🎯 Creating ECS Cluster..."
if aws ecs describe-clusters --clusters $ECS_CLUSTER --region $AWS_REGION 2>/dev/null | grep -q $ECS_CLUSTER; then
    echo "✅ ECS Cluster already exists"
else
    aws ecs create-cluster \
        --cluster-name $ECS_CLUSTER \
        --region $AWS_REGION \
        --capacity-providers FARGATE FARGATE_SPOT
    echo "✅ ECS Cluster created"
fi

# Step 5: Create VPC and Networking (if not using default)
echo ""
echo "🌐 Setting up VPC and Networking..."

# Get default VPC
DEFAULT_VPC=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text)
if [ "$DEFAULT_VPC" != "None" ] && [ ! -z "$DEFAULT_VPC" ]; then
    echo "✅ Using default VPC: $DEFAULT_VPC"
    
    # Get default subnet
    DEFAULT_SUBNET=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$DEFAULT_VPC" --query 'Subnets[0].SubnetId' --output text)
    echo "✅ Using default Subnet: $DEFAULT_SUBNET"
    
    # Get default security group
    DEFAULT_SG=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$DEFAULT_VPC" "Name=group-name,Values=default" --query 'SecurityGroups[0].GroupId' --output text)
    echo "✅ Using default Security Group: $DEFAULT_SG"
else
    echo "⚠️  No default VPC found. Please create VPC and subnets manually or modify this script."
    exit 1
fi

# Step 6: Update Security Group
echo ""
echo "🔓 Updating Security Group..."
if ! aws ec2 describe-security-groups --group-ids $DEFAULT_SG --query "SecurityGroups[0].IpPermissions[?FromPort==\`$APP_PORT\`]" --region $AWS_REGION 2>/dev/null | grep -q $APP_PORT; then
    aws ec2 authorize-security-group-ingress \
        --group-id $DEFAULT_SG \
        --protocol tcp \
        --port $APP_PORT \
        --cidr 0.0.0.0/0 \
        --region $AWS_REGION || true
    echo "✅ Security group updated for port $APP_PORT"
fi

# Step 7: Create ECS Task Definition
echo ""
echo "📋 Creating ECS Task Definition..."
TASK_DEF_FILE="/tmp/task-definition.json"
sed "s/YOUR_AWS_ACCOUNT_ID/$AWS_ACCOUNT_ID/g" aws/ecs-task-definition.json > $TASK_DEF_FILE

if aws ecs describe-task-definition --task-definition $TASK_FAMILY --region $AWS_REGION 2>/dev/null; then
    echo "✅ Task Definition already exists"
else
    aws ecs register-task-definition \
        --cli-input-json file://$TASK_DEF_FILE \
        --region $AWS_REGION
    echo "✅ Task Definition registered"
fi

# Step 8: Create ECS Service
echo ""
echo "🚀 Creating ECS Service..."
if aws ecs describe-services --cluster $ECS_CLUSTER --services $ECS_SERVICE --region $AWS_REGION 2>/dev/null | grep -q $ECS_SERVICE; then
    echo "✅ ECS Service already exists"
else
    aws ecs create-service \
        --cluster $ECS_CLUSTER \
        --service-name $ECS_SERVICE \
        --task-definition $TASK_FAMILY \
        --desired-count $DESIRED_COUNT \
        --launch-type FARGATE \
        --network-configuration "awsvpcConfiguration={subnets=[$DEFAULT_SUBNET],securityGroups=[$DEFAULT_SG],assignPublicIp=ENABLED}" \
        --region $AWS_REGION
    echo "✅ ECS Service created"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✅ AWS ECS/Fargate Setup Complete!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "📌 Next Steps:"
echo ""
echo "1. Push Docker image to ECR:"
echo "   docker build -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:latest ."
echo "   aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
echo "   docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:latest"
echo ""
echo "2. Set GitHub Secrets:"
echo "   - AWS_ACCESS_KEY_ID"
echo "   - AWS_SECRET_ACCESS_KEY"
echo ""
echo "3. Deploy:"
echo "   git push main"
echo "   GitHub Actions will automatically build and deploy!"
echo ""
echo "4. Monitor deployment:"
echo "   aws ecs describe-services --cluster $ECS_CLUSTER --services $ECS_SERVICE --region $AWS_REGION"
echo ""
echo "5. View logs:"
echo "   aws logs tail $LOG_GROUP --follow"
echo ""
