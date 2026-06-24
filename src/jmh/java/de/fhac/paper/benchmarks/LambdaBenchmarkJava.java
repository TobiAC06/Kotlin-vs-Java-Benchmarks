package de.fhac.paper.benchmarks;

import org.openjdk.jmh.annotations.*;
import org.openjdk.jmh.infra.Blackhole;

import java.util.*;
import java.util.concurrent.TimeUnit;

@BenchmarkMode(Mode.AverageTime)
@OutputTimeUnit(TimeUnit.MILLISECONDS)
@State(Scope.Thread)
public class LambdaBenchmarkJava {

    @Param({"100000"})
    int size;

    List<Integer> data;

    @Setup
    public void setup() {
        data = new ArrayList<>(size);
        for (int i = 0; i < size; i++) data.add(i);
    }

    @Benchmark
    public void stream(Blackhole bh) {
        bh.consume(data.stream().filter(x -> x % 2 == 0).mapToInt(x -> x).sum());
    }

    @Benchmark
    public void loop(Blackhole bh) {
        int sum = 0;
        for (int x : data) {
            if (x % 2 == 0) sum += x;
        }
        bh.consume(sum);
    }
}
