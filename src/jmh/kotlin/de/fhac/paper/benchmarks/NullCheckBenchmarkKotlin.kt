package de.fhac.paper.benchmarks

import org.openjdk.jmh.annotations.*
import java.util.concurrent.TimeUnit


@BenchmarkMode(Mode.AverageTime)
@OutputTimeUnit(TimeUnit.MILLISECONDS)
@State(Scope.Thread)
open class NullCheckBenchmarkKotlin {

    @Param("100000")
    var size: Int = 0

    @Benchmark
    fun run(): Int {
        var sum = 0
        for (i in 0..<size) {
            val s = if (i % 2 == 0) "x" else "y"
            sum += s.length
        }
        return sum
    }
}