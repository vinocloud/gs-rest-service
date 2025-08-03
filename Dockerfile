# Use a suitable JDK base image
FROM openjdk:17-jdk-slim

# Set a working directory inside the container
# This is the directory where the application will reside within the container
WORKDIR /app

# Copy the Gradle wrapper, its configuration, and the main build files
# These paths are relative to the Docker build context (which will be 'gs-rest-service' folder)
COPY complete/gradlew .
COPY complete/gradlew.bat . 
COPY complete/gradle gradle/ 

# Copy the core build files for Gradle
COPY complete/build.gradle .
COPY complete/settings.gradle .

# Grant execute permissions to the Gradle wrapper
RUN chmod +x gradlew

# Set the working directory *inside the container* to where the Gradle project actually is
# This is crucial for './gradlew bootJar' to find the source code and other project files.
WORKDIR /app/complete

# Copy the source code last (for better Docker layer caching)
COPY complete/src src/

# Run the Gradle build task to create the executable JAR
# bootJar is standard for Spring Boot Gradle projects
RUN ./gradlew bootJar

# After building, the JAR will be in /app/complete/build/libs/ (inside the container)
# We need to copy it to the main /app directory for the final ENTRYPOINT
# Get back to the root of our app directory inside the container for the final JAR
WORKDIR /app

# Define the JAR file name based on your build.gradle
# This typically comes from your project name or `bootJar.archiveFileName` in build.gradle
# Example: build/libs/gs-rest-service-0.0.1-SNAPSHOT.jar (adjust as per your actual build)
# The `*` in `complete/build/libs/*.jar` is a wildcard for the actual JAR filename.
ARG JAR_FILE=complete/build/libs/*.jar
COPY ${JAR_FILE} app.jar

# Define the command to run when the container starts
ENTRYPOINT ["java", "-jar", "app.jar"]
