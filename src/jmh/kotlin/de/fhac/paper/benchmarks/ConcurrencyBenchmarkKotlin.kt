package de.fhac.paper.benchmarks
import kotlinx.coroutines.*
import org.openjdk.jmh.annotations.*
import org.openjdk.jmh.infra.Blackhole
import java.util.concurrent.TimeUnit

@BenchmarkMode(Mode.AverageTime)
@OutputTimeUnit(TimeUnit.MILLISECONDS)
@State(Scope.Thread)
open class ConcurrencyBenchmarkKotlin {

    @Param("100000")
    var size: Int = 0

    @Benchmark
    fun run(bh: Blackhole) = runBlocking {
        val result = (0 until size)
            .map { i -> async { 42 * i } }
            .awaitAll()
            .sum()

        bh.consume(result)
    }
}