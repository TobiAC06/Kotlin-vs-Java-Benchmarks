package de.fhac.paper.benchmarks
import kotlinx.coroutines.*
import org.openjdk.jmh.annotations.*
import java.util.concurrent.TimeUnit

@BenchmarkMode(Mode.AverageTime)
@OutputTimeUnit(TimeUnit.MILLISECONDS)
@State(Scope.Thread)
open class ConcurrencyBenchmarkKotlin {

    @Param("100000")
    var size: Int = 0

    @Benchmark
    fun run(): Int = runBlocking {
        coroutineScope {
            val jobs = (0..<size).map { i ->
                async {
                    42 * i
                }
            }
            jobs.awaitAll().sum()
        }
    }
}