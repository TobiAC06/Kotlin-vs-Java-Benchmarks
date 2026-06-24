# =====================================================================
#  Stage 1 – Build
#  Uses the full JDK 25 image to compile and assemble the fat JAR.
# =====================================================================
FROM eclipse-temurin:25-jdk AS build

WORKDIR /app

# Copy Gradle wrapper first so Docker can cache the download layer
COPY gradlew gradlew
COPY gradle/ gradle/
RUN chmod +x gradlew

# Dependency layer: copy only build files, let Gradle resolve deps
COPY build.gradle.kts settings.gradle.kts ./

# Pre-fetch dependencies (cached as long as build files don't change)
RUN ./gradlew dependencies --no-daemon -q || true

# Copy source code and build the JMH shadow JAR
COPY src/ src/
RUN ./gradlew jmhJar --no-daemon -q

# =====================================================================
#  Stage 2 – Run
#  Lean runtime image; no build tooling needed.
# =====================================================================
FROM eclipse-temurin:25-jre AS run

WORKDIR /benchmarks

# Pull only the assembled JAR from the build stage
COPY --from=build /app/build/libs/*-jmh.jar benchmarks.jar

# Result directory (mount a host volume here to persist results)
RUN mkdir -p results

# Default entry point – all JVM flags and JMH options can be overridden
# by passing arguments after the image name in `docker run`.
ENTRYPOINT ["java", \
    "-XX:+UseG1GC", \
    "-Xms4g", "-Xmx4g", \
    "-jar", "benchmarks.jar"]

# Sensible defaults: run every benchmark, dump JSON results
CMD ["-prof", "gc", \
     "-v", "EXTRA", \
     "-rff", "results/jmh-results.json", \
     "-rf", "json"]

# =====================================================================
#  Stage 3 – Analyse
#  Lightweight Python image; runs analyze_benchmarks.py against the
#  JSON results produced by the run stage.
# =====================================================================
FROM python:3.14-slim AS analyse

WORKDIR /analyse

# Install Python dependencies
RUN pip install --no-cache-dir matplotlib numpy

# Copy the analysis script
COPY analysis/analyze_benchmarks.py .

# Results are expected at /results (mount the same host volume used in run)
VOLUME ["/results"]

# Default: read results/jmh-results.json, write plots to results/
ENTRYPOINT ["python", "analyze_benchmarks.py"]
CMD ["/results/jmh-results.json", "--out-dir", "/results"]