# Multi-stage build - optimized for size and security
FROM openjdk:17-slim as builder
WORKDIR /workspace
ARG JAR_FILE=target/user-crud-app-1.0.0.jar
COPY ${JAR_FILE} app.jar
RUN java -Djarmode=layertools -jar app.jar extract

# Final stage
FROM openjdk:17-slim
WORKDIR /app

# Create a non-root user for security
RUN useradd -m -u 1000 appuser

# Copy layers from builder
COPY --from=builder --chown=appuser:appuser /workspace/spring-boot-loader/ ./
COPY --from=builder --chown=appuser:appuser /workspace/dependencies/ ./
COPY --from=builder --chown=appuser:appuser /workspace/snapshot-dependencies/ ./
COPY --from=builder --chown=appuser:appuser /workspace/application/ ./

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD java -cp app:libs/* org.springframework.boot.loader.JarLauncher || exit 1

# Run the application
ENTRYPOINT ["java", "org.springframework.boot.loader.JarLauncher"]
