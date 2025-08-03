# Stage 1: Build the Spring Boot application
FROM openjdk:17.0.1-jdk-slim AS build  # This worked, keep it!
WORKDIR /app
COPY gradlew .
COPY gradle gradle
COPY build.gradle .
COPY settings.gradle .
COPY src src
RUN chmod +x gradlew
RUN ./gradlew bootJar

# Stage 2: Create the final production image
FROM openjdk:17.0.1-jdk-slim           # <-- CHANGE THIS LINE to use the JDK slim version
WORKDIR /app
COPY --from=build /app/build/libs/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
