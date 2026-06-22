# Java vs. Kotlin – JMH Benchmark Suite

Dieses Repository enthält die Benchmark-Implementierungen zur empirischen Studie
**„Eine empirische Analyse der Performance und Speicherverwaltung von Java und Kotlin"**.

Ziel der Studie ist ein systematischer Vergleich beider Sprachen hinsichtlich
Laufzeitperformance und Speicherverbrauch unter identischen Bedingungen auf der JVM.

---

## Projektstruktur

```
.
├── JavaBenchmarks/        # JMH-Benchmarks in Java
│   └── src/main/java/org/paper/benchmarks/
└── KotlinBenchmarks/      # JMH-Benchmarks in Kotlin
    └── src/main/kotlin/
```

Beide Teilprojekte sind eigenständige Gradle-Projekte und verwenden dieselbe
JMH-Version, sodass die Ergebnisse direkt vergleichbar sind.

---

## Benchmark-Szenarien

> Die konkreten Benchmark-Klassen befinden sich aktuell in Entwicklung.
> Geplante Szenarien:

| Szenario | Beschreibung | Java-spezifisch | Kotlin-spezifisch |
|---|---|---|---|
| **Arithmetik / Schleifen** | Einfache numerische Berechnungen | `int`, `long` | `Int`, `Long` (primitiv vs. nullable) |
| **String-Verarbeitung** | Verkettung, Splitting, Regex | `String` | `String` + Extension Functions |
| **Kollektion / Iteration** | Sortieren, Filtern, Aggregieren | `ArrayList`, Streams | `List`, Sequences, Lambdas |
| **Lambda / Higher-Order Functions** | Übergabe von Funktionsobjekten | Anonyme Klassen / Lambdas | `inline`-Funktionen vs. reguläre Lambdas |
| **Boxing / Unboxing** | Nullable primitive Typen | `Integer` vs. `int` | `Int?` vs. `Int` |
| **Nullsicherheit** | Null-Checks zur Laufzeit | Explizite `null`-Prüfungen | Kotlin Null-Safety (`?.`, `!!`) |
| **Objekt-Allokation / GC** | Kurzlebige Objekterzeugung im Heap | POJO-Allokation | Data Classes, Inline Value Classes |

---

## Voraussetzungen

| Komponente | Version |
|---|---|
| JDK | 21 (LTS) |
| Kotlin | 2.x |
| Gradle | 9.3.0 (Wrapper enthalten) |
| JMH | 1.37 |
| Docker | 24+ (empfohlen) |

---

## Empfehlung: Ausführung in Docker

Um die Reproduzierbarkeit der Ergebnisse zu gewährleisten, wird die Ausführung aller
Benchmarks **innerhalb eines Docker-Containers** empfohlen. Dies stellt sicher, dass
JDK-Version, Betriebssystem-Umgebung und verfügbare Ressourcen auf allen Maschinen
identisch sind – eine wesentliche Voraussetzung für vergleichbare Messergebnisse.

```bash
# Image bauen
docker build -t jvm-benchmarks .

# Java-Benchmarks ausführen
docker run --rm -v "$(pwd)/results:/results" jvm-benchmarks java \
  -jar JavaBenchmarks/build/libs/benchmarks.jar -wi 5 -i 10 -f 3

# Kotlin-Benchmarks ausführen
docker run --rm -v "$(pwd)/results:/results" jvm-benchmarks java \
  -jar KotlinBenchmarks/build/libs/benchmarks.jar -wi 5 -i 10 -f 3
```

> **Hinweis:** Für eine stabile Messung sollte der Container mit festen CPU- und
> RAM-Limits gestartet werden (`--cpus="2"`, `--memory="4g"`), damit der Host-Scheduler
> keinen Einfluss auf die Ergebnisse hat. Außerdem empfiehlt es sich, während der
> Messung keine weiteren ressourcenintensiven Prozesse auf dem Host laufen zu lassen.

---

## Benchmarks ausführen

### Java

```bash
cd JavaBenchmarks
./gradlew jmhJar
java -jar build/libs/benchmarks.jar -wi 5 -i 10 -f 3
```

### Kotlin

```bash
cd KotlinBenchmarks
./gradlew jmhJar
java -jar build/libs/benchmarks.jar -wi 5 -i 10 -f 3
```

### JMH-Parameter

| Parameter | Bedeutung | Wert |
|---|---|---|
| `-wi` | Warmup-Iterationen | 5 |
| `-i` | Mess-Iterationen | 10 |
| `-f` | Forks (separate JVM-Prozesse) | 3 |
| `-bm` | Benchmark-Modus | `avgt` (Average Time) |
| `-tu` | Zeiteinheit | `ms` |

> Die Warmup-Phase ist essenziell, da die JVM zunächst im Interpreter läuft und
> erst nach ausreichend vielen Aufrufen in nativen Maschinencode kompiliert
> (Tiered Compilation, C1 → C2). Messungen ohne Warmup erfassen kein
> stationäres Verhalten und sind nicht repräsentativ.

---

## Speichermessung

Zur Analyse der Heap-Nutzung und GC-Pausenzeiten werden die JVM-Flags
`-Xlog:gc*` sowie async-profiler / JFR eingesetzt:

```bash
java -Xlog:gc*:file=gc.log -jar build/libs/benchmarks.jar
```

Ausgewertet werden:
- Allokationsrate (Objekte/s, Bytes/s)
- GC-Häufigkeit und Pausenzeiten (G1GC)
- Heap-Belegung nach vollständigem GC

---

## Methodik & Validität

Die Benchmark-Gestaltung folgt den JMH-Richtlinien sowie den erweiterten
Empfehlungen von Schiavio et al. (SAC '26), um irreführende JIT-Optimierungen
durch unrealistische Ausführungsprofile zu vermeiden:

- **Blackhole-Konsumierung** aller berechneten Werte (verhindert Dead Code Elimination)
- **Separate JVM-Prozesse** pro Benchmark-Fork (verhindert JIT-Kontamination)
- **Realistische Eingabedaten** (keine konstanten Werte, die Constant Folding auslösen)
- **Reproduzierbarkeit** durch fixierten Random-Seed bei datengenerierenden Szenarien

---

## Zugehörige Publikation

Dieses Repository begleitet die Seminararbeit:

> *Eine empirische Analyse der Performance und Speicherverwaltung von Java und Kotlin*

Relevante Referenzen: Flauzino et al. (SBCARS '18), Pereira et al. (SLE '17),
Nanz & Furia (ICSE '15), Blackburn et al. – DaCapo (OOPSLA '06).

---

## Lizenz

MIT
