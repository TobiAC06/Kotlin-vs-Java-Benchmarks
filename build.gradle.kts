plugins {
    java
    kotlin("jvm") version "2.4.0"
    id("me.champeau.jmh") version "0.7.2"
}

group = "de.fhach.paper"
version = "1.0"

repositories {
    mavenCentral()
}

dependencies {
    jmh(kotlin("stdlib"))
    jmh("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.10.2")
    jmh("org.openjdk.jmh:jmh-core:1.37")
    annotationProcessor("org.openjdk.jmh:jmh-generator-annprocess:1.37")
}

kotlin {
    jvmToolchain(25)
}

jmh {
    jvmArgs.addAll("-XX:+UseG1GC", "-Xms4g", "-Xmx4g")
    warmupIterations.set(10)
    iterations.set(50)
    fork.set(4)
    profilers.add("gc")
    resultFormat.set("JSON")
    resultsFile.set(project.file("results/jmh-results.json"))
}