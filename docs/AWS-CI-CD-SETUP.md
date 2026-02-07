# GitHub Actions & AWS ECS/Fargate CI/CD Deployment Guide

## 📋 Overview

This guide provides step-by-step instructions for setting up automated CI/CD deployment to AWS ECS/Fargate using GitHub Actions.

**Architecture:**
```
GitHub Push → GitHub Actions → Build Docker Image → Push to AWS ECR → 
Deploy to AWS ECS/Fargate → Running Application
```

---

## 🏗️ Architecture Components

### **GitHub Actions Workflow**
- **Trigger**: Push to `main` branch
- **Jobs**:
  1. **Build & Push to ECR** - Compiles, builds Docker image, pushes to AWS ECR
  2. **Deploy to ECS** - Updates task definition and deploys to Fargate
  3. **Security Scan** - Scans code and Docker image for vulnerabilities
  4. **Tests** - Runs unit tests

### **AWS Services Used**
- **ECR (Elastic Container Registry)** - Docker image repository
- **ECS (Elastic Container Service)** - Container orchestration
- **Fargate** - Serverless container compute
- **CloudWatch** - Logging and monitoring
- **IAM** - Identity and access management
- **ALB (Application Load Balancer)** - Optional load balancing

---

## 📋 Prerequisites

### **AWS Account Setup**
1. AWS account with appropriate permissions
2. AWS CLI installed locally
3. IAM user with ECS, ECR, and IAM permissions

### **GitHub Setup**
1. GitHub repository (already done)
2. GitHub secrets configured
3. Git push access to `main` branch

---

## 🔑 Step 1: Create AWS Credentials

### **Option A: Using AWS Console**

1. Go to [AWS IAM Console](https://console.aws.amazon.com/iam/)
2. Create new IAM user for GitHub Actions:
   - Click "Users" → "Create user"
   - Username: `github-actions-user`
   - Enable programmatic access

3. Attach policies:
   - `AmazonEC2ContainerRegistryPowerUser` (ECR access)
   - `AmazonECS_FullAccess` (ECS access)
   - `IAMFullAccess` (IAM access)

4. Generate access key:
   - Save **Access Key ID** and **Secret Access Key**

### **Option B: Using AWS CLI**

```bash
# Create user
aws iam create-user --user-name github-actions-user

# Create access key
aws iam create-access-key --user-name github-actions-user

# Attach policies
aws iam attach-user-policy \
  --user-name github-actions-user \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser

aws iam attach-user-policy \
  --user-name github-actions-user \
  --policy-arn arn:aws:iam::aws:policy/AmazonECS_FullAccess

aws iam attach-user-policy \
  --user-name github-actions-user \
  --policy-arn arn:aws:iam::aws:policy/IAMFullAccess
```

---

## 🔐 Step 2: Configure GitHub Secrets

### **In GitHub Repository Settings:**

1. Go to your repository
2. Settings → Secrets and variables → Actions
3. Click "New repository secret"

Add these secrets:

| Secret Name | Value |
|---|---|
| `AWS_ACCESS_KEY_ID` | Your AWS Access Key ID |
| `AWS_SECRET_ACCESS_KEY` | Your AWS Secret Access Key |

**Screenshot steps:**
```
GitHub → Repository → Settings → Secrets and variables → Actions → 
New repository secret → Add AWS_ACCESS_KEY_ID → Add AWS_SECRET_ACCESS_KEY
```

---

## ⚙️ Step 3: Setup AWS Infrastructure

### **Automated Setup (Recommended)**

```bash
# Make script executable
chmod +x aws/setup-ecs-fargate.sh

# Run setup script
./aws/setup-ecs-fargate.sh
```

**What the script does:**
- ✅ Creates ECR repository
- ✅ Creates CloudWatch log group
- ✅ Creates IAM roles
- ✅ Creates ECS cluster
- ✅ Updates security group
- ✅ Registers task definition
- ✅ Creates ECS service

### **Manual Setup (Alternative)**

If the script doesn't work, follow these steps:

#### **1. Create ECR Repository**
```bash
aws ecr create-repository \
  --repository-name user-crud-app \
  --region us-east-1
```

#### **2. Create CloudWatch Log Group**
```bash
aws logs create-log-group --log-group-name /ecs/user-crud-app
aws logs put-retention-policy --log-group-name /ecs/user-crud-app --retention-in-days 30
```

#### **3. Create IAM Roles**
```bash
# Save this to trust-policy.json
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

# Create execution role
aws iam create-role \
  --role-name ecsTaskExecutionRole \
  --assume-role-policy-document file://trust-policy.json

aws iam attach-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

# Create task role
aws iam create-role \
  --role-name ecsTaskRole \
  --assume-role-policy-document file://trust-policy.json
```

#### **4. Create ECS Cluster**
```bash
aws ecs create-cluster --cluster-name user-crud-app-cluster
```

#### **5. Create ECS Service**
```bash
aws ecs create-service \
  --cluster user-crud-app-cluster \
  --service-name user-crud-app-service \
  --task-definition user-crud-app-task \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxxxx],securityGroups=[sg-xxxxx],assignPublicIp=ENABLED}"
```

---

## 🚀 Step 4: Deploy via GitHub Actions

### **Automatic Deployment**

Simply push to the `main` branch:

```bash
git add .
git commit -m "deployment changes"
git push origin main
```

GitHub Actions will automatically:
1. Check out code
2. Build Maven project
3. Build Docker image
4. Push to ECR
5. Deploy to ECS
6. Run security scans
7. Run tests

### **Monitor Deployment**

**In GitHub:**
1. Go to repository
2. Click "Actions" tab
3. Watch the workflow run in real-time

**Commands to check deployment:**
```bash
# Check service status
aws ecs describe-services \
  --cluster user-crud-app-cluster \
  --services user-crud-app-service \
  --region us-east-1

# Check running tasks
aws ecs list-tasks \
  --cluster user-crud-app-cluster \
  --region us-east-1

# View logs
aws logs tail /ecs/user-crud-app --follow

# Get task details
aws ecs describe-tasks \
  --cluster user-crud-app-cluster \
  --tasks <task-arn> \
  --region us-east-1
```

---

## 🌐 Step 5: Access Your Application

### **Get the Public IP/URL**

```bash
# List tasks
TASK_ARN=$(aws ecs list-tasks \
  --cluster user-crud-app-cluster \
  --service-name user-crud-app-service \
  --query 'taskArns[0]' \
  --output text)

# Get task details
aws ecs describe-tasks \
  --cluster user-crud-app-cluster \
  --tasks $TASK_ARN \
  --region us-east-1

# Get ENI details
ENI_ID=$(aws ecs describe-tasks \
  --cluster user-crud-app-cluster \
  --tasks $TASK_ARN \
  --region us-east-1 \
  --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value[0]' \
  --output text)

# Get public IP
aws ec2 describe-network-interfaces \
  --network-interface-ids $ENI_ID \
  --query 'NetworkInterfaces[0].Association.PublicIp' \
  --output text
```

**Access Application:**
```
http://<PUBLIC_IP>:8080/users
```

---

## 📊 GitHub Actions Workflow Details

### **Workflow File**
Location: `.github/workflows/deploy.yml`

### **Jobs Explanation**

#### **Job 1: build-and-push**
```yaml
- Runs on: ubuntu-latest
- Only on: push to main branch
- Steps:
  1. Checkout code
  2. Setup Java 17
  3. Build with Maven
  4. Configure AWS credentials
  5. Login to ECR
  6. Build Docker image
  7. Push to ECR
```

#### **Job 2: deploy-to-ecs**
```yaml
- Runs on: ubuntu-latest
- Depends on: build-and-push job
- Steps:
  1. Checkout code
  2. Configure AWS credentials
  3. Download task definition
  4. Update image in task definition
  5. Deploy to ECS service
  6. Wait for service stability
```

#### **Job 3: security-scan**
```yaml
- Runs on: ubuntu-latest
- Steps:
  1. Scan filesystem with Trivy
  2. Upload results to GitHub Security
```

#### **Job 4: test**
```yaml
- Runs on: ubuntu-latest
- Steps:
  1. Checkout code
  2. Setup Java 17
  3. Run Maven tests
  4. Upload test results
```

---

## 🔄 Continuous Deployment Pipeline

```
┌─────────────────────────────────────────────────────────┐
│ Developer pushes to main branch                          │
└────────────────┬────────────────────────────────────────┘
                 │
         ┌───────▼────────┐
         │ GitHub Actions │
         │ Workflow Start │
         └───────┬────────┘
                 │
    ┌────────────┼────────────┬────────────┬──────────────┐
    │            │            │            │              │
┌───▼──┐  ┌─────▼──┐  ┌─────▼──┐  ┌────▼─────┐  ┌────▼────┐
│Build │  │  Test  │  │ Scan   │  │ Build    │  │ Deploy  │
│Maven │  │ Maven  │  │Security│  │ Docker   │  │to ECS   │
└─┬────┘  └──┬─────┘  └─┬──────┘  └─┬───────┘  └────┬────┘
  │          │         │          │           │
  └──────────┴─────────┴──────────┴───────────┴─────┘
             │
      ┌──────▼──────┐
      │ Push to ECR │
      └──────┬──────┘
             │
      ┌──────▼──────────┐
      │ Update Task Def │
      └──────┬──────────┘
             │
      ┌──────▼───────────────┐
      │ Deploy to ECS Fargate│
      └──────┬───────────────┘
             │
      ┌──────▼──────────┐
      │ Running on AWS  │
      │  Application    │
      └─────────────────┘
```

---

## 🐛 Troubleshooting

### **GitHub Actions Fails**

**Check logs:**
```
GitHub → Actions → Click failed workflow → Click job → View logs
```

**Common errors:**

| Error | Solution |
|-------|----------|
| "Invalid credentials" | Check AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY secrets |
| "ECR repository not found" | Run `aws/setup-ecs-fargate.sh` |
| "Task definition not found" | Ensure task family name matches in workflow |
| "Service not found" | Create ECS service manually |

### **ECS Deployment Issues**

**Check service status:**
```bash
aws ecs describe-services \
  --cluster user-crud-app-cluster \
  --services user-crud-app-service \
  --region us-east-1
```

**Check task logs:**
```bash
aws logs tail /ecs/user-crud-app --follow
```

**Restart service:**
```bash
aws ecs update-service \
  --cluster user-crud-app-cluster \
  --service user-crud-app-service \
  --force-new-deployment
```

---

## 📈 Monitoring & Logs

### **CloudWatch Logs**
```bash
# View logs
aws logs tail /ecs/user-crud-app --follow

# Get specific log stream
aws logs describe-log-streams \
  --log-group-name /ecs/user-crud-app

# View logs from specific time
aws logs filter-log-events \
  --log-group-name /ecs/user-crud-app \
  --start-time $(date -d "30 minutes ago" +%s)000
```

### **ECS Metrics**
```bash
# Get task count
aws ecs describe-services \
  --cluster user-crud-app-cluster \
  --services user-crud-app-service \
  --query 'services[0].runningCount'

# List all tasks
aws ecs list-tasks --cluster user-crud-app-cluster
```

---

## 🔒 Security Best Practices

✅ **Implemented:**
- Non-root user in Docker image
- Health checks in task definition
- CloudWatch logging
- IAM roles with least privilege
- Security scanning with Trivy

✅ **Additional Recommendations:**
- Use Secrets Manager for sensitive data
- Enable VPC endpoint for ECR
- Use private subnets for ECS tasks
- Enable container image scanning in ECR
- Implement WAF for ALB (if using)
- Use KMS for encryption

---

## 🎯 Next Steps

1. ✅ Configure AWS credentials
2. ✅ Add GitHub secrets
3. ✅ Run `aws/setup-ecs-fargate.sh`
4. ✅ Push to main branch
5. ✅ Monitor GitHub Actions
6. ✅ Access your application

---

## 📚 Useful Commands

### **View Deployment History**
```bash
aws ecs describe-services \
  --cluster user-crud-app-cluster \
  --services user-crud-app-service \
  --region us-east-1 \
  --query 'services[0].deployments'
```

### **Rollback Deployment**
```bash
aws ecs update-service \
  --cluster user-crud-app-cluster \
  --service user-crud-app-service \
  --task-definition user-crud-app-task:PREVIOUS_REVISION
```

### **Scale Service**
```bash
aws ecs update-service \
  --cluster user-crud-app-cluster \
  --service user-crud-app-service \
  --desired-count 3
```

### **View Task Logs**
```bash
aws logs tail /ecs/user-crud-app --follow --log-stream-names <task-name>
```

---

## 🆘 Support & Resources

- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Spring Boot on AWS](https://aws.amazon.com/blogs/developer/using-spring-boot-on-aws/)

