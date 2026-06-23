package de.fhac.paper.benchmarks;

import org.openjdk.jmh.annotations.*;

import java.util.*;
import java.util.concurrent.*;

@BenchmarkMode(Mode.AverageTime)
@OutputTimeUnit(java.util.concurrent.TimeUnit.MILLISECONDS)
@State(Scope.Thread)
public class VirtualThreadBenchmarkJava {

    @Param({"100000"})
    int size;

    @Benchmark
    public long virtualThreads() throws Exception {
        try (ExecutorService executor = Executors.newVirtualThreadPerTaskExecutor()) {
            List<Future<Integer>> futures = new ArrayList<>();
            for (int i = 0; i < size; i++) {
                int finalI = i;
                futures.add(executor.submit(() -> 42 * finalI));
            }
            long sum = 0;
            for (Future<Integer> f : futures) sum += f.get();
            return sum;
        }
    }
}