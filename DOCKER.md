# Docker & Containerization Guide

## 🐳 Building the Docker Image

### Prerequisites
- Docker installed on your machine
- Docker Compose (optional, for orchestration)

### Build the Image

```bash
# Build the Docker image
docker build -t user-crud-app:latest .

# Build with a specific tag
docker build -t user-crud-app:1.0.0 .
```

### View Built Images

```bash
docker images
```

---

## ▶️ Running the Container

### Option 1: Using Docker Run (Simple)

```bash
# Run the container
docker run -d \
  -p 8080:8080 \
  --name user-crud-app \
  user-crud-app:latest

# Verify container is running
docker ps

# View logs
docker logs user-crud-app

# Follow logs in real-time
docker logs -f user-crud-app
```

### Option 2: Using Docker Compose (Recommended)

```bash
# Start the application
docker-compose up -d

# View logs
docker-compose logs app

# Follow logs
docker-compose logs -f app

# Stop the application
docker-compose down

# Stop and remove volumes
docker-compose down -v
```

---

## 🌐 Accessing the Application

Once running, access the application at:

```
http://localhost:8080/users
```

---

## 📊 Docker Commands Reference

### Container Management

```bash
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# Start a stopped container
docker start user-crud-app

# Stop a running container
docker stop user-crud-app

# Restart a container
docker restart user-crud-app

# Remove a container
docker rm user-crud-app

# View container logs
docker logs user-crud-app

# Execute command in running container
docker exec -it user-crud-app bash
```

### Image Management

```bash
# List images
docker images

# Remove an image
docker rmi user-crud-app:latest

# Tag an image
docker tag user-crud-app:latest user-crud-app:1.0.0

# Push to Docker Hub
docker push your-username/user-crud-app:latest
```

### Debugging

```bash
# Access container shell
docker exec -it user-crud-app bash

# Inspect container details
docker inspect user-crud-app

# Check resource usage
docker stats user-crud-app

# View container events
docker events --filter "container=user-crud-app"
```

---

## 🔧 Dockerfile Explanation

The `Dockerfile` uses **multi-stage build** for optimization:

### Stage 1: Builder
```dockerfile
FROM openjdk:17-slim as builder
WORKDIR /workspace
COPY target/user-crud-app-1.0.0.jar app.jar
RUN java -Djarmode=layertools -jar app.jar extract
```

**What it does:**
- Creates a temporary builder stage
- Extracts Spring Boot JAR into layers
- Optimizes for layer caching

### Stage 2: Runtime
```dockerfile
FROM openjdk:17-slim
RUN useradd -m -u 1000 appuser
COPY --from=builder /workspace/spring-boot-loader/ ./
USER appuser
EXPOSE 8080
ENTRYPOINT ["java", "org.springframework.boot.loader.JarLauncher"]
```

**What it does:**
- Uses lightweight `openjdk:17-slim` (65MB vs 200MB+)
- Creates non-root user for security
- Copies only necessary layers
- Exposes port 8080
- Sets health check

**Benefits:**
- ✅ Smaller image size (~200MB)
- ✅ Faster startup (layer caching)
- ✅ Better security (non-root user)
- ✅ Healthcheck support

---

## 📦 Docker Compose Explanation

### Services
```yaml
services:
  app:
    build: .              # Build from Dockerfile
    ports:
      - "8080:8080"      # Map port 8080
    healthcheck:         # Health monitoring
    networks:            # Custom network
    restart: unless-stopped
```

### Features
- **Port Mapping**: Maps container port 8080 to host port 8080
- **Health Check**: Checks `/users` endpoint every 30s
- **Auto-restart**: Restarts on failure unless manually stopped
- **Custom Network**: Isolates containers for communication

### Optional Services (Commented)
- PostgreSQL database for production use
- Volume for persistent data storage

---

## 🚀 Deployment Scenarios

### Scenario 1: Local Development
```bash
# Build and run with compose
docker-compose up --build -d

# Access at http://localhost:8080/users

# View real-time logs
docker-compose logs -f app
```

### Scenario 2: Production on Single Server
```bash
# Build optimized image
docker build -t user-crud-app:prod .

# Run with resource limits
docker run -d \
  -p 8080:8080 \
  --memory="512m" \
  --cpus="1" \
  --restart=always \
  user-crud-app:prod

# Monitor
docker stats
```

### Scenario 3: Cloud Deployment (AWS, GCP, Azure)

#### Push to Docker Hub
```bash
# Login to Docker Hub
docker login

# Tag image
docker tag user-crud-app:latest your-username/user-crud-app:latest

# Push image
docker push your-username/user-crud-app:latest
```

#### Deploy on AWS ECS
```bash
# Use AWS CLI or Console to create task definition
# Reference Docker Hub image: your-username/user-crud-app:latest
```

#### Deploy on Azure Container Instances
```bash
az container create \
  --resource-group myResourceGroup \
  --name user-crud-app \
  --image your-username/user-crud-app:latest \
  --ports 8080 \
  --cpu 1 \
  --memory 512
```

#### Deploy on Kubernetes
```bash
# Create deployment
kubectl create deployment user-crud-app \
  --image=your-username/user-crud-app:latest

# Expose service
kubectl expose deployment user-crud-app \
  --type=LoadBalancer \
  --port=8080

# Check status
kubectl get pods
kubectl get svc
```

---

## 🔐 Security Best Practices

✅ **Implemented in our Dockerfile:**
- Non-root user (`appuser`)
- Lightweight base image (`openjdk:17-slim`)
- Layer caching for faster rebuilds
- Health checks for monitoring

✅ **Additional Recommendations:**
- Use `.dockerignore` to exclude unnecessary files
- Regularly update base images
- Use secrets management for sensitive data
- Scan images for vulnerabilities:
  ```bash
  docker scan user-crud-app:latest
  ```

---

## 📈 Performance Optimization

### Image Size
- Current: ~200MB (with multi-stage build)
- Without multi-stage: ~500MB+

### Startup Time
- Cold start: ~5-10 seconds
- Warm start: ~2-3 seconds

### Resource Usage
- Default memory: 512MB (configurable)
- CPU: 1 core (configurable)

---

## 🧪 Testing the Container

### Health Check
```bash
# Test health endpoint
curl http://localhost:8080/users

# Check container health
docker inspect --format='{{json .State.Health}}' user-crud-app
```

### Add Test Data
```bash
# Once container is running, add a user via UI or API
curl -X POST http://localhost:8080/users \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "name=John&address=123 Main St"
```

---

## 📝 Environment Variables

Default variables in `docker-compose.yml`:

```yaml
environment:
  - SPRING_APPLICATION_NAME=user-crud-app
  - SERVER_PORT=8080
```

### Adding Custom Variables

```yaml
environment:
  - SPRING_APPLICATION_NAME=user-crud-app
  - SERVER_PORT=8080
  - SPRING_JPA_HIBERNATE_DDL_AUTO=create-drop
  - LOGGING_LEVEL_ROOT=INFO
```

---

## 🛑 Stopping & Cleanup

```bash
# Stop all services
docker-compose down

# Remove stopped containers
docker system prune

# Remove unused images
docker image prune

# Remove all dangling data
docker system prune -a --volumes
```

---

## 📚 Useful Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Spring Boot Docker Guide](https://spring.io/guides/gs/spring-boot-docker/)
- [Java on Docker Best Practices](https://docs.docker.com/language/java/)

---

## ⚠️ Troubleshooting

### Container exits immediately
```bash
docker logs user-crud-app
```

### Port already in use
```bash
# Change port in docker-compose.yml
ports:
  - "8081:8080"  # Host:Container
```

### Out of memory
```bash
docker run -d --memory="1g" user-crud-app:latest
```

### Permission denied errors
```bash
# Non-root user issue (shouldn't happen with our setup)
docker exec -u root user-crud-app bash
```

---

## 🎉 Next Steps

1. **Build the image**: `docker build -t user-crud-app:latest .`
2. **Run with compose**: `docker-compose up -d`
3. **Access the app**: http://localhost:8080/users
4. **Monitor logs**: `docker-compose logs -f app`
5. **Push to registry**: `docker push your-username/user-crud-app:latest`
6. **Deploy to cloud**: Use your cloud provider's container service

