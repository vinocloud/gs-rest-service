# Use a suitable JDK base image
FROM openjdk:17-jdk-slim

# Set the primary application directory inside the container
WORKDIR /app

# Copy the entire 'complete' directory into '/app'
# This brings all Gradle files (gradlew, gradle/, build.gradle, settings.gradle, src/)
# into /app/complete/ within the container.
COPY complete /app/complete

# Set the working directory *inside the container* to the root of your actual Gradle project.
# This makes subsequent commands like './gradlew' relative to the project root.
WORKDIR /app/complete

# Grant execute permissions to the Gradle wrapper
RUN chmod +x gradlew

# Run the Gradle build task to create the executable JAR
# Now ./gradlew will work directly as gradlew is in /app/complete/
RUN ./gradlew bootJar

# After building, the JAR will be in /app/complete/build/libs/ (inside the container)
# We need to copy it to the main /app directory for the final ENTRYPOINT
WORKDIR /app

# Define the JAR file name based on your build.gradle
# The path is now relative to /app/ as 'complete' is a subdir of /app/
ARG JAR_FILE=complete/build/libs/*.jar
COPY ${JAR_FILE} app.jar

# Define the command to run when the container starts
ENTRYPOINT ["java", "-jar", "app.jar"]
