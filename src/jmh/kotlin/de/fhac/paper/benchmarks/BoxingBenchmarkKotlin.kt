package de.fhac.paper.benchmarks

import org.openjdk.jmh.annotations.*
import java.util.concurrent.TimeUnit

@BenchmarkMode(Mode.AverageTime)
@OutputTimeUnit(TimeUnit.MILLISECONDS)
@State(Scope.Thread)
open class BoxingBenchmarkKotlin {
    @Param("100000")
    var size: Int = 0

    lateinit var primitive: IntArray
    lateinit var boxed: MutableList<Int>

    @Setup
    fun setup() {
        primitive = IntArray(size)
        boxed = ArrayList(size)

        for (i in 0..<size) {
            primitive[i] = i
            boxed.add(i)
        }
    }

    @Benchmark
    fun primitiveSum(): Long {
        var sum: Long = 0
        for (v in primitive) sum += v.toLong()
        return sum
    }

    @Benchmark
    fun boxedSum(): Long {
        var sum: Long = 0
        for (v in boxed) sum += v.toLong()
        return sum
    }
}
