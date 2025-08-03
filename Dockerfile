# Use a suitable JDK base image
FROM openjdk:17-jdk-slim

# Set the working directory inside the container
WORKDIR /app

# Copy Gradle wrapper, its configuration, and build files
# These paths are relative to the build context, which will be 'gs-rest-service'
COPY gs-rest-service/complete/gradlew .
COPY gs-rest-service/complete/gradlew.bat . 
COPY gs-rest-service/complete/gradle gs-rest-service/complete/gradle
COPY gs-rest-service/complete/build.gradle .
COPY gs-rest-service/complete/settings.gradle .

# Grant execute permissions to the Gradle wrapper
RUN chmod +x gradlew

# Run the Gradle build to download dependencies and build the project
# Ensure the working directory is set correctly for gradlew to find files
# We'll set WORKDIR to /app/complete inside the container for the build
# Then copy the final JAR from there.

# Temporarily set WORKDIR to where gradle files will be copied for the build process
WORKDIR /app/complete

# Copy the source code last (for better caching)
COPY gs-rest-service/complete/src src

# Run the Gradle build (adjust if you need specific tasks like 'bootJar')
RUN ./gradlew bootJar

# Get back to the root of our app directory inside the container for the final JAR
WORKDIR /app

# Define the JAR file name based on your build.gradle (e.g., usually target/your-app-name.jar or build/libs/your-app-name.jar)
# Replace 'your-app-name-0.0.1-SNAPSHOT.jar' with your actual JAR name.
# You might need to check your build.gradle for `bootJar.archiveFileName` or `jar.archiveFileName`
# Or, if you don't define a specific name, it's often based on your project name and version.
# Common for Spring Boot: build/libs/your-project-name.jar
ARG JAR_FILE=complete/build/libs/*.jar
COPY ${JAR_FILE} app.jar

ENTRYPOINT ["java", "-jar", "app.jar"]
