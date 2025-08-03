# Use a suitable JDK base image
FROM openjdk:17-jdk-slim

# Set a working directory inside the container
WORKDIR /app

# Copy the Gradle wrapper, its configuration, and the main build files
# These paths are relative to the Docker build context (which is the repo root, where Dockerfile is)
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
RUN ./gradlew bootJar

# After building, the JAR will be in /app/complete/build/libs/ (inside the container)
# We need to copy it to the main /app directory for the final ENTRYPOINT
WORKDIR /app

# Define the JAR file name based on your build.gradle
ARG JAR_FILE=complete/build/libs/*.jar
COPY ${JAR_FILE} app.jar

# Define the command to run when the container starts
ENTRYPOINT ["java", "-jar", "app.jar"]
