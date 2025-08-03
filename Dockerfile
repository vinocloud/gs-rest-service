# Use a suitable JDK base image.
FROM openjdk:17-jdk-slim

# --- Builder Stage ---
# Name this stage 'builder' so we can reference it later
FROM openjdk:17-jdk-slim AS builder

# Set the primary application directory inside the builder container
WORKDIR /app

# Copy the entire 'complete' directory into '/app' within the builder stage.
COPY complete /app/complete

# Set the working directory *inside the builder container* to the root of your Maven project.
WORKDIR /app/complete

# Grant execute permissions to the Maven wrapper script.
RUN chmod +x mvnw

# Certificate Import Section (only needed in the builder stage)
COPY ca_cert.pem /tmp/ca_cert.pem
RUN keytool -import -alias custom_ca_cert -file /tmp/ca_cert.pem -keystore $JAVA_HOME/lib/security/cacerts -storepass changeit -noprompt && \
    rm /tmp/ca_cert.pem

# Run the Maven build to create the executable JAR.
RUN ./mvnw clean package -DskipTests

# --- Runtime Stage ---
# Use a smaller base image for the final application, as it only needs a JRE, not a full JDK.
FROM openjdk:17-jre-slim # Using JRE for a smaller final image

# Set the application directory in the final runtime container
WORKDIR /app

# Copy the built JAR from the 'builder' stage into the final 'app' directory.
# This is the crucial change: --from=builder specifies to copy from the previous stage.
# The path 'app/complete/target/*.jar' is relative to the WORKDIR of the 'builder' stage,
# which was '/app/complete', so the absolute path to the JAR within the builder stage is correct.
COPY --from=builder /app/complete/target/*.jar app.jar

# --- Define Container Entrypoint ---
ENTRYPOINT ["java", "-jar", "app.jar"]
