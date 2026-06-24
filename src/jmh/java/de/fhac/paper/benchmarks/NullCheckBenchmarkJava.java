package de.fhac.paper.benchmarks;

import org.openjdk.jmh.annotations.*;

import java.util.concurrent.TimeUnit;

@BenchmarkMode(Mode.AverageTime)
@OutputTimeUnit(TimeUnit.MILLISECONDS)
@State(Scope.Thread)
public class NullCheckBenchmarkJava {

    @Param({"100000"})
    int size;

    @Benchmark
    public int run() {
        int sum = 0;
        for (int i = 0; i < size; i++) {
            String s = (i % 2 == 0) ? "x" : "y";
            if (s == null) throw new NullPointerException();
            sum += s.length();
        }
        return sum;
    }
}