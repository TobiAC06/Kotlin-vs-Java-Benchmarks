package de.fhac.paper.benchmarks

import org.openjdk.jmh.annotations.*
import java.util.concurrent.TimeUnit

@BenchmarkMode(Mode.AverageTime)
@OutputTimeUnit(TimeUnit.MILLISECONDS)
@State(Scope.Thread)
class LambdaBenchmarkKotlin {
    @Param("100000")
    var size: Int = 0

    lateinit var data: MutableList<Int>

    @Setup
    fun setup() {
        data = ArrayList(size)
        for (i in 0..<size) data.add(i)
    }

    @Benchmark
    fun stream(): Int {
        return data.stream()
            .filter { x: Int? -> x!! % 2 == 0 }
            .mapToInt { x: Int? -> x!! }
            .sum()
    }

    @Benchmark
    fun loop(): Int {
        var sum = 0
        for (x in data) {
            if (x % 2 == 0) sum += x
        }
        return sum
    }
}