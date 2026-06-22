package de.fhac.paper.benchmarks;

import org.openjdk.jmh.annotations.*;

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
    public boolean sieve() {
        for (int i = 2; i * i < size; i++) {
            if (isPrime[i]) {
                for (int j = i * i; j < size; j += i) {
                    isPrime[j] = false;
                }
            }
        }
        return isPrime[size - 1];
    }
}
