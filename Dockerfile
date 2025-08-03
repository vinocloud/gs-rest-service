# Use a suitable JDK base image.
# It's good practice to use a specific version rather than just '17-jdk-slim'.
# For example, openjdk:17.0.10-jdk-slim (check for the latest patch version).
FROM openjdk:17-jdk-slim

# Set the primary application directory inside the container.
# This will be the base for our application's files.
WORKDIR /app

# --- Copy Maven Project Files ---
# Copy the entire 'complete' directory into '/app'.
# This brings all Maven project files (pom.xml, mvnw, .mvn/, src/)
# into /app/complete/ within the container, preserving the project structure.
COPY complete /app/complete

# --- Configure Maven Wrapper ---
# Set the working directory *inside the container* to the root of your actual Maven project.
# This is where `pom.xml`, `mvnw`, etc., are located after the COPY.
# Subsequent commands like `./mvnw` will then be executed from this directory.
WORKDIR /app/complete

# Grant execute permissions to the Maven wrapper script.
RUN chmod +x mvnw

# --- Certificate Import Section (Crucial for Repository Access) ---
# IMPORTANT: Place your 'ca_cert.pem' (containing trusted CA certificates)
# in the same directory as your Dockerfile on your host machine.
# This file should contain the certificates needed to trust Maven Central,
# Gradle Plugin Repository, or any corporate proxy CAs.

COPY ca_cert.pem /tmp/ca_cert.pem

# Import the certificates into the Java trust store (cacerts) inside the container.
# The default cacerts password for OpenJDK is 'changeit'.
# '-noprompt' prevents the command from asking for confirmation.
# The '&& rm' part cleans up the temporary cert file after import.
RUN keytool -import -alias custom_ca_cert -file /tmp/ca_cert.pem -keystore $JAVA_HOME/lib/security/cacerts -storepass changeit -noprompt && \
    rm /tmp/ca_cert.pem

# --- Maven Build Step ---
# Run the Maven build to compile, test, and package the application into an executable JAR.
# -B (or --batch-mode) runs Maven in non-interactive mode.
# -DskipTests skips running unit/integration tests during the build.
# 'package' goal will produce the JAR file.
RUN ./mvnw clean package -DskipTests

# --- Prepare Final JAR for Execution ---
# After building, the executable JAR is typically found in 'target/' directory
# inside your Maven project's root (which is /app/complete in the container).
# Change back to the main /app directory to store the final JAR there for clarity.
WORKDIR /app

# Define the path to the executable JAR.
# This uses a wildcard '*' to match the specific version in the JAR filename.
# Example: 'complete/target/gs-rest-service-0.0.1-SNAPSHOT.jar'
ARG JAR_FILE=complete/target/*.jar
COPY ${JAR_FILE} app.jar

# --- Define Container Entrypoint ---
# This specifies the command to run when the Docker container starts.
# It executes the Spring Boot application's JAR file.
ENTRYPOINT ["java", "-jar", "app.jar"]
