# src/adservice/Dockerfile
ARG BUILDPLATFORM=linux/amd64

FROM --platform=$BUILDPLATFORM eclipse-temurin:24-jdk-alpine AS builder

WORKDIR /app

COPY build.gradle gradlew ./
COPY gradle ./gradle

RUN chmod +x gradlew

RUN ./gradlew downloadRepos

COPY . .

RUN ./gradlew installDist

FROM eclipse-temurin:24-jre-alpine

WORKDIR /app

COPY --from=builder \
    /app/build/install/hipstershop \
    /app/hipstershop

EXPOSE 9555

ENTRYPOINT ["/app/hipstershop/bin/AdService"]