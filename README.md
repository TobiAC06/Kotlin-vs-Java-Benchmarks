# Java vs. Kotlin - JMH Benchmark Suite

Empirical analysis of runtime performance and memory management of Java and Kotlin on the JVM.
Accompanies the paper *"Eine empirische Analyse der Performance und Speicherverwaltung von Java und Kotlin"*.

---

## Table of Contents

1. [Project Structure](#project-structure)
2. [Requirements](#requirements)
3. [Quick Start](#quick-start)
4. [Building](#building)
5. [Running Benchmarks](#running-benchmarks)
6. [Analysing Results](#analysing-results)
7. [Benchmark Scenarios](#benchmark-scenarios)
8. [JMH Configuration](#jmh-configuration)
9. [Results](#results)
10. [JVM Flags & Reproducibility](#jvm-flags--reproducibility)

---

## Project Structure

```
.
├── src/jmh/
│   ├── java/de/fhac/paper/benchmarks/
│   │   ├── SieveBenchmarkJava.java          # Scenario 1 – Sieve of Eratosthenes
│   │   ├── BoxingBenchmarkJava.java         # Scenario 2 – Primitive vs. boxed
│   │   ├── LambdaBenchmarkJava.java         # Scenario 3 – Stream / lambda
│   │   ├── NullCheckBenchmarkJava.java      # Scenario 4 – Null check
│   │   └── VirtualThreadBenchmarkJava.java  # Scenario 5 – Virtual Threads
│   └── kotlin/de/fhac/paper/benchmarks/
│       ├── SieveBenchmarkKotlin.kt          # Scenario 1 – Sieve of Eratosthenes
│       ├── BoxingBenchmarkKotlin.kt         # Scenario 2 – IntArray vs. List<Int>
│       ├── LambdaBenchmarkKotlin.kt         # Scenario 3 – inline vs. non-inline
│       ├── NullCheckBenchmarkKotlin.kt      # Scenario 4 – Kotlin null-safety
│       └── CoroutineBenchmarkKotlin.kt      # Scenario 5 – Coroutines
├── analysis/
│   └── analyze_benchmarks.py               # Plot generator (runtime + memory)
├── results/                                # JSON output and generated plots land here
├── build.gradle.kts
├── Dockerfile
├── build.sh   / build.bat                  # Linux/macOS and Windows (CMD/PowerShell)
└── run.sh     / run.bat
```

---

## Requirements

| Tool        | Version                   | Notes                             |
|-------------|---------------------------|-----------------------------------|
| Docker      | ≥ 24                      | Required for containerised runs   |
| JDK (local) | 25                        | Only needed for local Gradle runs |
| Gradle      | via wrapper (`./gradlew`) | No separate install needed        |

---

## Quick Start

**Linux / macOS**
```bash
# 1. Build both Docker images
./build.sh

# 2. Run all benchmarks and generate plots in one step
./run.sh all

# 3. Inspect results
cat results/jmh-results.json
open results/benchmark_runtime.png
open results/benchmark_memory.png
```

**Windows (CMD or PowerShell)**
```bat
build.bat
run.bat all
```

---

## Building

### Docker images (recommended)

The project uses two Docker images — one for running benchmarks, one for analysis.

**Linux / macOS**
```bash
./build.sh          # builds both images with tag :latest
./build.sh v2       # builds both images with tag :v2
```

**Windows**
```bat
build.bat           :: builds both images with tag :latest
build.bat v2        :: builds both images with tag :v2
```

The Dockerfile uses a three-stage build:

| Stage       | Base image                  | Purpose                                              |
|-------------|-----------------------------|------------------------------------------------------|
| `build`     | `eclipse-temurin:25-jdk`    | Compiles sources and assembles the JMH fat JAR       |
| `run`       | `eclipse-temurin:25-jre`    | Lean runtime image; contains only the JAR            |
| `analyse`   | `python:3.12-slim`          | Runs `analyze_benchmarks.py`; produces PNG plots     |

### Local (without Docker)

```bash
./gradlew jmhJar
```

The fat JAR will be at `build/libs/<project>-jmh.jar`.

---

## Running Benchmarks

The run scripts accept an optional command as the first argument:

| Command    | Effect                                    |
|------------|-------------------------------------------|
| `bench`    | Run benchmarks only (default)             |
| `analyse`  | Generate plots from existing results      |
| `all`      | Run benchmarks, then generate plots       |

All further flags are optional. Defaults mirror `build.gradle.kts`.

| Flag      | Default | Description                       |
|-----------|---------|-----------------------------------|
| `-wi <n>` | `10`    | Warmup iterations                 |
| `-i <n>`  | `50`    | Measurement iterations            |
| `-f <n>`  | `4`     | Forks (independent JVM processes) |
| `FILTER`  | *(all)* | Benchmark name / regex            |

### Linux / macOS

```bash
./run.sh                              # full benchmark run with defaults
./run.sh all                          # benchmark + analyse
./run.sh analyse                      # analyse existing results
./run.sh Sieve                        # Scenario 1 only
./run.sh Boxing                       # Scenario 2 only
./run.sh Lambda                       # Scenario 3 only
./run.sh NullCheck                    # Scenario 4 only
./run.sh "Coroutine|VirtualThread"    # Scenario 5 only
./run.sh -wi 3 -i 5 -f 1             # quick smoke-test
./run.sh -wi 3 -i 5 -f 1 Boxing      # smoke-test, Boxing only
```

### Windows (CMD or PowerShell)

```bat
run.bat                              :: full benchmark run with defaults
run.bat all                          :: benchmark + analyse
run.bat analyse                      :: analyse existing results
run.bat Sieve                        :: Scenario 1 only
run.bat Boxing                       :: Scenario 2 only
run.bat Lambda                       :: Scenario 3 only
run.bat NullCheck                    :: Scenario 4 only
run.bat "Coroutine|VirtualThread"    :: Scenario 5 only
run.bat -wi 3 -i 5 -f 1             :: quick smoke-test
run.bat -wi 3 -i 5 -f 1 Boxing      :: smoke-test, Boxing only
```

### Run via Gradle (local JDK required)

```bash
./gradlew jmh
```

### Run the fat JAR directly

```bash
java \
  -XX:+UseG1GC -Xms4g -Xmx4g \
  -jar build/libs/*-jmh.jar \
  -wi 10 -i 50 -f 4 \
  -prof gc \
  -v EXTRA \
  -rff results/jmh-results.json \
  -rf json
```

---

## Analysing Results

The `analyse` stage reads `results/jmh-results.json` and produces two bar-chart PNGs in the same directory.

| File                    | Content                                           |
|-------------------------|---------------------------------------------------|
| `benchmark_runtime.png` | Mean execution time (ns/op) per scenario          |
| `benchmark_memory.png`  | Heap allocation per operation (B/op) per scenario |

### Via Docker (recommended)

```bash
./run.sh analyse           # Linux / macOS
run.bat  analyse           # Windows
```

### Directly with Python

```bash
pip install matplotlib numpy
python analysis/analyze_benchmarks.py results/jmh-results.json
# plots land in the current directory

python analysis/analyze_benchmarks.py results/jmh-results.json --out-dir results/ --dpi 200
```

---

## Benchmark Scenarios

| # | Name                      | Java                                                          | Kotlin                                 | What is measured                                                                       |
|---|---------------------------|---------------------------------------------------------------|----------------------------------------|----------------------------------------------------------------------------------------|
| 1 | **Sieve of Eratosthenes** | `SieveBenchmarkJava`                                          | `SieveBenchmarkKotlin`                 | Baseline — raw loop performance on primitive arrays, no language-specific constructs   |
| 2 | **Primitive Boxing**      | `int[]` vs `List<Integer>`                                    | `IntArray` vs `List<Int>`              | Allocation pressure from autoboxing; GC frequency and pause times                      |
| 3 | **Lambda / Stream**       | `Stream.filter/map`                                           | `.asSequence.filter/sum`               | Whether Kotlin's `Sequences` are comparable to Java streams                            |
| 4 | **Null-Safety**           | Manual `Objects.requireNonNull`                               | Kotlin nullable parameter (`String?`)  | Runtime overhead of Kotlin's compiler-inserted null checks                             |
| 5 | **Concurrency**           | Virtual Threads (`Executors.newVirtualThreadPerTaskExecutor`) | Coroutines (`async`/`awaitAll`)        | Scheduling overhead and heap allocation for 10⁵ short-lived tasks                      |

All scenarios use `n = 100 000` as the default input size (`@Param("100000")`).

---

## JMH Configuration

| Parameter              | Value         | Rationale                                                                      |
|------------------------|---------------|--------------------------------------------------------------------------------|
| Warmup iterations      | 10 × 2 s      | Ensures C2 JIT has fully compiled hotpaths before measurement begins           |
| Measurement iterations | 50 × 2 s      | High iteration count reduces statistical noise                                 |
| Forks                  | 4             | Each fork is a fresh JVM process; eliminates JIT state carry-over between runs |
| Benchmark mode         | `AverageTime` | Reports average time per operation (ms/op)                                     |
| GC profiler            | `gc`          | Records allocated bytes/op and GC pause times via JMH's `GCProfiler`           |
| Output format          | JSON          | Machine-readable; suitable for downstream analysis                             |

The configuration follows the extended guidelines of Schiavio et al. (SAC '26) to avoid misleading microbenchmark results caused by unrealistic JVM profiles.

---

## Results

Output is written to `results/jmh-results.json` (bind-mounted from the container to the host).

Each entry contains:

- `benchmark` — fully qualified benchmark method name
- `mode` — `avgt`
- `primaryMetric.score` / `scoreUnit` — mean time per operation
- `secondaryMetrics` — GC allocation rate (`·gc.alloc.rate`), GC pause time (`·gc.time`), etc.

After running `analyse`, two plot files are added to the same directory:

- `results/benchmark_runtime.png`
- `results/benchmark_memory.png`

---

## JVM Flags & Reproducibility

All runs use:

```
-XX:+UseG1GC   # G1 GC explicitly enabled (default since Java 9, but can be overridden by env)
-Xms4g         # Initial heap = max heap → prevents GC-triggered heap expansion during measurement
-Xmx4g         # Maximum heap fixed at 4 GB
```

> **Note on absolute values:** reported times depend on the host hardware. Only *relative* differences between Java and Kotlin within the same run are meaningful for the analysis.

The full execution environment (JDK version, GC, heap) is pinned by the Docker image tag `eclipse-temurin:25-jdk`, ensuring reproducible results across machines.
