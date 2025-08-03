# Use a suitable JDK base image for the builder stage.
FROM openjdk:17-jdk-slim AS builder # Keep the AS builder here

# Set the primary application directory inside the builder container
WORKDIR /app

# Copy the entire 'complete' directory into '/app' within the builder stage.
COPY complete /app/complete

# Set the working directory *inside the builder container* to the root of your Maven project.
WORKDIR /app/complete

# Grant execute permissions to the Maven wrapper script.
RUN chmod +x mvnw

# --- Certificate Import Section (only needed in the builder stage) ---
COPY ca_cert.pem /tmp/ca_cert.pem
RUN keytool -import -alias custom_ca_cert -file /tmp/ca_cert.pem -keystore $JAVA_HOME/lib/security/cacerts -storepass changeit -noprompt && \
    rm /tmp/ca_cert.pem
# --- END Certificate Import Section ---

# Run the Maven build to create the executable JAR.
RUN ./mvnw clean package -DskipTests

# --- Runtime Stage ---
# Use a smaller base image for the final application, as it only needs a JRE, not a full JDK.
FROM openjdk:17-jre-slim # This line is now clean, comment is above

# Set the application directory in the final runtime container
WORKDIR /app

# Copy the built JAR from the 'builder' stage into the final 'app' directory.
COPY --from=builder /app/complete/target/*.jar app.jar

# --- Define Container Entrypoint ---
ENTRYPOINT ["java", "-jar", "app.jar"]
