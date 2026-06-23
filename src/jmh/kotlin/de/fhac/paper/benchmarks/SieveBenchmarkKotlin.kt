package de.fhac.paper.benchmarks

import org.openjdk.jmh.annotations.*
import java.util.*
import java.util.concurrent.TimeUnit

@BenchmarkMode(Mode.AverageTime)
@OutputTimeUnit(TimeUnit.MILLISECONDS)
@State(Scope.Thread)
open class SieveBenchmarkKotlin{

    @Param("100000")
    var size: Int = 0

    lateinit var isPrime: BooleanArray

    @Setup
    fun setup() {
        isPrime = BooleanArray(size)
        Arrays.fill(isPrime, true)
    }

    @Benchmark
    fun sieve(): Boolean {
        var i = 2
        while (i * i < size) {
            if (isPrime[i]) {
                var j = i * i
                while (j < size) {
                    isPrime[j] = false
                    j += i
                }
            }
            i++
        }
        return isPrime[size - 1]
    }
}