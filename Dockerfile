# Use a suitable JDK base image for the builder stage.
FROM openjdk:17-jdk-slim AS builder

# Set the primary application directory inside the builder container
WORKDIR /app

# Copy the entire 'complete' directory into '/app' within the builder stage.
COPY complete /app/complete

# Set the working directory *inside the builder container* to the root of your Maven project.
WORKDIR /app/complete

# Grant execute permissions to the Maven wrapper script.
RUN chmod +x mvnw

# --- Certificate Import Section (only needed in the builder stage) ---
# IMPORTANT: Place your 'ca_cert.pem' (containing trusted CA certificates)
# in the same directory as your Dockerfile on your host machine.
# This file should contain the certificates needed to trust Maven Central,
# Gradle Plugin Repository, or any corporate proxy CAs.
COPY ca_cert.pem /tmp/ca_cert.pem
RUN keytool -import -alias custom_ca_cert -file /tmp/ca_cert.pem -keystore $JAVA_HOME/lib/security/cacerts -storepass changeit -noprompt && \
    rm /tmp/ca_cert.pem
# --- END Certificate Import Section ---

# Run the Maven build to create the executable JAR.
# -B (or --batch-mode) runs Maven in non-interactive mode.
# -DskipTests skips running unit/integration tests during the build.
# 'package' goal will produce the JAR file.
RUN ./mvnw clean package -DskipTests

# --- Runtime Stage ---
# Use a smaller base image for the final application, as it only needs a JRE, not a full JDK.
FROM openjdk:17-jre-slim

# Set the application directory in the final runtime container
WORKDIR /app

# Copy the built JAR from the 'builder' stage into the final 'app' directory.
COPY --from=builder /app/complete/target/*.jar app.jar

# --- Define Container Entrypoint ---
# This specifies the command to run when the Docker container starts.
# It executes the Spring Boot application's JAR file.
ENTRYPOINT ["java", "-jar", "app.jar"]
