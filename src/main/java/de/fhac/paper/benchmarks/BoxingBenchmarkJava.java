package de.fhac.paper.benchmarks;

import org.openjdk.jmh.annotations.*;

import java.util.*;
import java.util.concurrent.TimeUnit;

@BenchmarkMode(Mode.AverageTime)
@OutputTimeUnit(TimeUnit.MILLISECONDS)
@State(Scope.Thread)
public class BoxingBenchmarkJava {

    @Param({"100000"})
    int size;

    int[] primitive;
    List<Integer> boxed;

    @Setup
    public void setup() {
        primitive = new int[size];
        boxed = new ArrayList<>(size);

        for (int i = 0; i < size; i++) {
            primitive[i] = i;
            boxed.add(i);
        }
    }

    @Benchmark
    public long primitiveSum() {
        long sum = 0;
        for (int v : primitive) sum += v;
        return sum;
    }

    @Benchmark
    public long boxedSum() {
        long sum = 0;
        for (Integer v : boxed) sum += v;
        return sum;
    }
}
