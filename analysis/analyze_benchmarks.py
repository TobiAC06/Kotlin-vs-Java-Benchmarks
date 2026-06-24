#!/usr/bin/env python3
"""
analyze_benchmarks.py
=====================
Analysis and visualisation script for JMH benchmark results
(Java vs. Kotlin performance comparison).

Output files
------------
- benchmark_runtime.png  – runtime comparison (ns/op) per scenario
- benchmark_memory.png   – memory allocation (B/op, gc.alloc.rate.norm) per scenario

Usage
-----
    python analyze_benchmarks.py results.json
    python analyze_benchmarks.py results.json --out-dir ./plots
    python analyze_benchmarks.py results.json --out-dir ./plots --dpi 200

Input format
------------
The input file must be in JMH JSON format, as produced by the JMH flags
``-rf json -rff <filename>.json``.
Each entry in the array must contain the following fields:

    {
        "benchmark": "com.example.SomeBenchmarkJava.run",
        "primaryMetric": {
            "score": 123.45,
            "scoreError": 1.23,
            "scoreUnit": "ns/op"
        },
        "secondaryMetrics": {
            "gc.alloc.rate.norm": {
                "score": 456.0,
                "scoreError": "NaN"
            }
        }
    }

Benchmark class naming convention
----------------------------------
Classes must end with ``Java`` or ``Kotlin`` for automatic language detection:
    - ``SieveBenchmarkJava``   → language: Java,   scenario: SieveBenchmark
    - ``SieveBenchmarkKotlin`` → language: Kotlin, scenario: SieveBenchmark

Dependencies
------------
    pip install matplotlib numpy
"""

import argparse
import json
import sys
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

JAVA_COLOR = "#4A90D9"
KOTLIN_COLOR = "#B467C4"
BAR_WIDTH = 0.7          # width of each bar; both bars share one subplot
FIG_WIDTH_PER_PANEL = 3.2
FIG_HEIGHT = 5


# ---------------------------------------------------------------------------
# Data loading & parsing
# ---------------------------------------------------------------------------

def load_results(path: Path) -> dict:
    """Read a JMH JSON result file and return a structured dict:

        { (scenario, method): { "Java": {...}, "Kotlin": {...} }, ... }

    Raises
    ------
    SystemExit
        If the file is not found or does not contain valid JSON.
    """
    try:
        with path.open(encoding="utf-8") as fh:
            raw = json.load(fh)
    except FileNotFoundError:
        sys.exit(f"[Error] File not found: {path}")
    except json.JSONDecodeError as exc:
        sys.exit(f"[Error] Invalid JSON in {path}: {exc}")

    records: dict = {}
    skipped = 0

    for item in raw:
        bm = item.get("benchmark", "")
        parts = bm.split(".")
        cls = parts[-2] if len(parts) >= 2 else ""
        method = parts[-1]

        # Determine language and scenario name from the class suffix
        if cls.endswith("Java"):
            lang, scenario = "Java", cls[:-4]
        elif cls.endswith("Kotlin"):
            lang, scenario = "Kotlin", cls[:-6]
        else:
            skipped += 1
            continue

        # Primary metric (runtime)
        primary = item.get("primaryMetric", {})
        score = float(primary.get("score", 0))
        score_err_raw = primary.get("scoreError", "NaN")
        score_err = float(score_err_raw) if str(score_err_raw) != "NaN" else 0.0
        score_unit = primary.get("scoreUnit", "ns/op")

        # Secondary metric (heap allocation rate per operation)
        gc_metric = item.get("secondaryMetrics", {}).get("gc.alloc.rate.norm", {})
        mem = float(gc_metric.get("score", 0))
        mem_err_raw = gc_metric.get("scoreError", "NaN")
        mem_err = float(mem_err_raw) if str(mem_err_raw) != "NaN" else 0.0

        key = (scenario, method)
        records.setdefault(key, {})[lang] = {
            "score": score,
            "score_err": score_err,
            "score_unit": score_unit,
            "mem": mem,
            "mem_err": mem_err,
        }

    if skipped:
        print(f"[Warning] {skipped} entries skipped "
              f"(class names do not end with 'Java' or 'Kotlin').")

    if not records:
        sys.exit("[Error] No usable benchmark entries found.")

    return records


# ---------------------------------------------------------------------------
# Plot helpers
# ---------------------------------------------------------------------------

def _subplot_label(scenario: str, method: str) -> str:
    """Build a readable subplot title from the scenario and method name."""
    label = scenario.replace("Benchmark", "")
    if method not in ("run", "sieve"):
        label += f"\n.{method}"
    return label


def _add_value_labels(ax: plt.Axes, bars, values: list[float]) -> None:
    """Annotate each bar with its numeric value."""
    for bar, val in zip(bars, values):
        ax.text(
            bar.get_x() + bar.get_width() / 2,
            bar.get_height() * 1.03,
            f"{val:.3g}",
            ha="center", va="bottom",
            fontsize=9, fontweight="bold",
            )


def _style_ax(ax: plt.Axes, ylabel: str, label: str) -> None:
    """Apply consistent styling to an Axes instance."""
    ax.set_xticks([0, 1])
    ax.set_xticklabels(["Java", "Kotlin"], fontsize=11)
    ax.set_ylabel(ylabel, fontsize=9)
    ax.set_title(label, fontsize=10, fontweight="bold")
    ax.yaxis.grid(True, linestyle="--", alpha=0.5, zorder=0)
    ax.set_axisbelow(True)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)


# ---------------------------------------------------------------------------
# Plot functions
# ---------------------------------------------------------------------------

def plot_runtime(records: dict, out_path: Path, dpi: int) -> None:
    """Create the runtime bar chart and save it as a PNG."""
    comparisons = sorted(records.keys())
    n = len(comparisons)
    fig, axes = plt.subplots(1, n, figsize=(FIG_WIDTH_PER_PANEL * n, FIG_HEIGHT))
    if n == 1:
        axes = [axes]

    fig.suptitle(
        "JMH Benchmark – Runtime: Java vs. Kotlin",
        fontsize=14, fontweight="bold", y=1.02,
    )

    for ax, key in zip(axes, comparisons):
        scenario, method = key
        entry = records[key]
        java = entry.get("Java", {})
        kotlin = entry.get("Kotlin", {})

        vals = [java.get("score", 0), kotlin.get("score", 0)]
        errs = [java.get("score_err", 0), kotlin.get("score_err", 0)]
        unit = java.get("score_unit") or kotlin.get("score_unit", "ns/op")

        bars = ax.bar(
            [0, 1], vals, BAR_WIDTH,
            color=[JAVA_COLOR, KOTLIN_COLOR],
            yerr=errs, capsize=5,
            error_kw={"linewidth": 1.2},
            edgecolor="white", linewidth=0.5, zorder=3,
        )
        _style_ax(ax, unit, _subplot_label(scenario, method))
        _add_value_labels(ax, bars, vals)

    fig.tight_layout()
    fig.savefig(out_path, dpi=dpi, bbox_inches="tight")
    print(f"[OK] Runtime plot saved → {out_path}")
    plt.close(fig)


def plot_memory(records: dict, out_path: Path, dpi: int) -> None:
    """Create the memory allocation bar chart and save it as a PNG."""
    comparisons = sorted(records.keys())
    n = len(comparisons)
    fig, axes = plt.subplots(1, n, figsize=(FIG_WIDTH_PER_PANEL * n, FIG_HEIGHT))
    if n == 1:
        axes = [axes]

    fig.suptitle(
        "JMH Benchmark – Memory Allocation: Java vs. Kotlin",
        fontsize=14, fontweight="bold", y=1.02,
    )

    for ax, key in zip(axes, comparisons):
        scenario, method = key
        entry = records[key]
        java = entry.get("Java", {})
        kotlin = entry.get("Kotlin", {})

        vals = [java.get("mem", 0), kotlin.get("mem", 0)]
        errs = [java.get("mem_err", 0), kotlin.get("mem_err", 0)]

        bars = ax.bar(
            [0, 1], vals, BAR_WIDTH,
            color=[JAVA_COLOR, KOTLIN_COLOR],
            yerr=errs, capsize=5,
            error_kw={"linewidth": 1.2},
            edgecolor="white", linewidth=0.5, zorder=3,
        )
        _style_ax(ax, "B/op", _subplot_label(scenario, method))
        _add_value_labels(ax, bars, vals)

    fig.tight_layout()
    fig.savefig(out_path, dpi=dpi, bbox_inches="tight")
    print(f"[OK] Memory plot saved → {out_path}")
    plt.close(fig)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Visualise JMH benchmark results (Java vs. Kotlin) "
            "as runtime and memory allocation bar charts."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Examples:\n"
            "  python analyze_benchmarks.py results.json\n"
            "  python analyze_benchmarks.py results.json --out-dir ./plots\n"
            "  python analyze_benchmarks.py results.json --out-dir ./plots --dpi 200\n"
        ),
    )
    parser.add_argument(
        "input",
        type=Path,
        help="Path to the JMH result file in JSON format.",
    )
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=Path("."),
        metavar="DIR",
        help="Output directory for the PNG files (default: current directory).",
    )
    parser.add_argument(
        "--dpi",
        type=int,
        default=150,
        metavar="N",
        help="Resolution of the output images in DPI (default: 150).",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    # Create the output directory if it does not exist yet
    args.out_dir.mkdir(parents=True, exist_ok=True)

    print(f"[Info] Loading results from: {args.input}")
    records = load_results(args.input)
    print(f"[Info] {len(records)} benchmark scenario(s) loaded.")

    plot_runtime(records, args.out_dir / "benchmark_runtime.png", args.dpi)
    plot_memory(records, args.out_dir / "benchmark_memory.png", args.dpi)


if __name__ == "__main__":
    main()