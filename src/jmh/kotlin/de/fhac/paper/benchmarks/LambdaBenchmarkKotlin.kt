package de.fhac.paper.benchmarks

import org.openjdk.jmh.annotations.*
import org.openjdk.jmh.infra.Blackhole
import java.util.concurrent.TimeUnit

@BenchmarkMode(Mode.AverageTime)
@OutputTimeUnit(TimeUnit.MILLISECONDS)
@State(Scope.Thread)
open class LambdaBenchmarkKotlin {
    @Param("100000")
    var size: Int = 0

    lateinit var data: MutableList<Int>

    @Setup
    fun setup() {
        data = ArrayList(size)
        for (i in 0..<size) data.add(i)
    }

    @Benchmark
    fun stream(bh: Blackhole) {
        bh.consume(data.asSequence().filter { x: Int -> x % 2 == 0 }.sum())
    }
}