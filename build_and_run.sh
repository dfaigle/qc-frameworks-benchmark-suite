#!/usr/bin/env bash
# Lange Laeufe im Hintergrund auf einem Linux-Server (fuer kurze Laeufe und
# Windows/macOS: docker compose, siehe README).
#
#   ./build_and_run.sh benchmarks/qiskit_benchmark.py --qubits 8 --mode gradient
#   CPUS=16 MEMORY=128g ./build_and_run.sh benchmarks/abstraction_benchmark.py --framework pennylane --qubits 5 8 10 12
#
# Alle Argumente gehen unveraendert an python im Container. Ohne Argumente laeuft
# pennylane_benchmark.py mit Standard-Flags.
set -euo pipefail

IMAGE="abstraction-benchmark:latest"
CPUS="${CPUS:-$(nproc)}"
MEMORY="${MEMORY:-}"          # leer = kein Limit
NAME="bench_$(date +%Y%m%d_%H%M%S)"

if [ $# -eq 0 ]; then
    set -- benchmarks/pennylane_benchmark.py
fi

docker build --build-arg UID="$(id -u)" --build-arg GID="$(id -g)" -t "$IMAGE" .

mkdir -p raw_results

docker run -d --rm \
    -v "$(pwd)/benchmarks:/app/benchmarks:ro" \
    -v "$(pwd)/raw_results:/app/raw_results" \
    --shm-size=2g \
    --cpus "$CPUS" \
    ${MEMORY:+--memory "$MEMORY"} \
    -e OMP_NUM_THREADS="$CPUS" \
    -e MKL_NUM_THREADS="$CPUS" \
    -e OPENBLAS_NUM_THREADS="$CPUS" \
    -e NUMEXPR_NUM_THREADS="$CPUS" \
    --name "$NAME" \
    "$IMAGE" \
    "$@"

echo "Gestartet: $NAME   (Logs: docker logs -f $NAME)"
