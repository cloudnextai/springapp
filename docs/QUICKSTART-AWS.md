# Quick Start Guide - AWS ECS/Fargate Deployment

## 🚀 5-Minute Setup

Follow these steps to deploy your Spring Boot app to AWS ECS/Fargate with automated CI/CD.

---

## Step 1: Prepare AWS Account (2 minutes)

### Create IAM User for GitHub Actions

```bash
# Create user
aws iam create-user --user-name github-actions-user

# Create access key
aws iam create-access-key --user-name github-actions-user

# Attach permissions (run each command)
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

**Save the output** - you'll need:
- `AccessKeyId` → AWS_ACCESS_KEY_ID
- `SecretAccessKey` → AWS_SECRET_ACCESS_KEY

---

## Step 2: Configure GitHub Secrets (1 minute)

1. Go to GitHub repository: https://github.com/cloudnextai/springapp
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** twice:

| Name | Value |
|------|-------|
| `AWS_ACCESS_KEY_ID` | Your Access Key ID from Step 1 |
| `AWS_SECRET_ACCESS_KEY` | Your Secret Access Key from Step 1 |

---

## Step 3: Create AWS Infrastructure (1 minute)

Run the automated setup script:

```bash
# Make executable
chmod +x aws/setup-ecs-fargate.sh

# Run it
./aws/setup-ecs-fargate.sh
```

**What it creates:**
- ✅ ECR Repository (Docker image storage)
- ✅ ECS Cluster (Container orchestration)
- ✅ CloudWatch Logs (Monitoring)
- ✅ IAM Roles (Permissions)
- ✅ Task Definition (Container config)
- ✅ ECS Service (Running containers)

---

## Step 4: Trigger Deployment (1 minute)

Push to main branch:

```bash
git push origin main
```

This automatically:
1. Builds the Spring Boot app
2. Creates Docker image
3. Pushes to AWS ECR
4. Deploys to ECS Fargate
5. Runs tests and security scans

---

## Step 5: Access Your App (instant)

Get the public IP:

```bash
# Get the task ARN
TASK_ARN=$(aws ecs list-tasks \
  --cluster user-crud-app-cluster \
  --service-name user-crud-app-service \
  --query 'taskArns[0]' \
  --output text)

# Get the public IP
aws ecs describe-tasks \
  --cluster user-crud-app-cluster \
  --tasks $TASK_ARN \
  --region us-east-1 \
  --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value[0]' \
  --output text | xargs -I {} \
  aws ec2 describe-network-interfaces \
  --network-interface-ids {} \
  --query 'NetworkInterfaces[0].Association.PublicIp' \
  --output text
```

Open in browser: `http://<PUBLIC_IP>:8080/users`

---

## 🔍 Monitor Deployment

### GitHub Actions
- Go to repository → **Actions** tab
- Watch the workflow in real-time

### AWS Console
```bash
# Check service status
aws ecs describe-services \
  --cluster user-crud-app-cluster \
  --services user-crud-app-service \
  --region us-east-1

# View logs
aws logs tail /ecs/user-crud-app --follow

# Check running tasks
aws ecs list-tasks --cluster user-crud-app-cluster
```

---

## 🆘 Troubleshooting

### "Invalid credentials" error
- Double-check GitHub Secrets match AWS IAM credentials
- Ensure IAM user has required permissions

### "Repository not found" in GitHub Actions
- Run setup script: `./aws/setup-ecs-fargate.sh`

### Can't access application
- Check service is running: `aws ecs describe-services --cluster user-crud-app-cluster --services user-crud-app-service`
- Check logs: `aws logs tail /ecs/user-crud-app --follow`
- Get IP: Run Step 5 command above

### Workflow keeps failing
- Check GitHub Actions logs
- Verify AWS credentials are correct
- Ensure IAM user has all required permissions

---

## 📚 Full Documentation

For detailed setup and advanced configuration, see:
- [aws/CI-CD-SETUP.md](aws/CI-CD-SETUP.md) - Complete deployment guide
- [DOCKER.md](DOCKER.md) - Docker containerization guide
- [README.md](README.md) - Application overview

---

## 🎯 What Happens Now

Every time you:

```bash
git push origin main
```

GitHub Actions automatically:
1. ✅ Builds Spring Boot app with Maven
2. ✅ Runs unit tests
3. ✅ Scans for security vulnerabilities
4. ✅ Builds optimized Docker image
5. ✅ Pushes to AWS ECR
6. ✅ Updates ECS task definition
7. ✅ Deploys to Fargate (zero-downtime)
8. ✅ Monitors health checks
9. ✅ Alerts if anything fails

---

## 💡 Quick Commands Reference

```bash
# View deployment status
aws ecs describe-services --cluster user-crud-app-cluster --services user-crud-app-service --region us-east-1

# View logs
aws logs tail /ecs/user-crud-app --follow

# Check running tasks
aws ecs list-tasks --cluster user-crud-app-cluster

# Force new deployment
aws ecs update-service --cluster user-crud-app-cluster --service user-crud-app-service --force-new-deployment

# View GitHub Actions workflow
# https://github.com/cloudnextai/springapp/actions

# View AWS ECS console
# https://console.aws.amazon.com/ecs/
```

---

## ✅ Success Checklist

- [ ] AWS IAM user created
- [ ] Access keys generated
- [ ] GitHub secrets configured (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
- [ ] AWS setup script executed successfully
- [ ] Code pushed to main branch
- [ ] GitHub Actions workflow completed
- [ ] Application accessible at public IP
- [ ] Can view logs in CloudWatch

**Once all checked, you have fully automated CI/CD! 🎉**

