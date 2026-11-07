# Single Dockerfile for every Ticketly service: the jar is built on the host
# (make build) and copied in, which keeps image builds fast and cache-friendly.
#
#   docker build --build-arg JAR_FILE=services/user-service/target/user-service-0.1.0.jar -t ticketly/user-service .
FROM eclipse-temurin:21-jre-jammy

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

ARG JAR_FILE
ENV JAVA_OPTS=""

COPY ${JAR_FILE} /app/app.jar

WORKDIR /app
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar /app/app.jar"]
