package de.fhac.paper.benchmarks;

import org.openjdk.jmh.annotations.*;
import org.openjdk.jmh.infra.Blackhole;

import java.util.Arrays;
import java.util.concurrent.TimeUnit;

@BenchmarkMode(Mode.AverageTime)
@OutputTimeUnit(TimeUnit.MILLISECONDS)
@State(Scope.Thread)
public class SieveBenchmarkJava {

    @Param({"100000"})
    int size;

    boolean[] isPrime;

    @Setup
    public void setup() {
        isPrime = new boolean[size];
        Arrays.fill(isPrime, true);
    }

    @Benchmark
    public void sieve(Blackhole bh) {
        for (int i = 2; i * i < size; i++) {
            if (isPrime[i]) {
                for (int j = i * i; j < size; j += i) {
                    isPrime[j] = false;
                }
            }
        }
        bh.consume(isPrime[size - 1]);
    }
}
