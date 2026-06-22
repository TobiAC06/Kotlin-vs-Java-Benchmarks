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
    implementation(kotlin("stdlib"))
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.10.2")
    implementation("org.openjdk.jmh:jmh-core:1.37")
    annotationProcessor("org.openjdk.jmh:jmh-generator-annprocess:1.37")
}

kotlin {
    jvmToolchain(25)
}

jmh {
    warmupIterations.set(5)
    iterations.set(10)
    fork.set(2)
    resultFormat.set("JSON")
    resultsFile.set(project.file("results/jmh-results.json"))
}