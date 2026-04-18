FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /workspace

# Copy build descriptor first to maximize dependency caching.
COPY pom.xml ./
RUN mvn -q -DskipTests dependency:go-offline

# Copy source and build executable jar.
COPY src src
RUN mvn -q -DskipTests package

FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /workspace/target/*.jar /app/app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
