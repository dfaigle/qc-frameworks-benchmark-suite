# Image fuer die Benchmarks. Laeuft auf Windows, macOS und Linux (Docker Desktop
# oder Docker Engine), ohne Git-Submodule und ohne SSH-Key.
#
# Schnellstart (siehe README):
#   docker compose up --build                  # kurzer Demo-Lauf aller vier Benchmarks
#   docker compose run --rm bench benchmarks/qiskit_benchmark.py --qubits 8 --mode gradient

FROM python:3.12-slim

# Commit des qc-executor, gegen den die Ergebnisse der Arbeit gemessen wurden.
# Entspricht dem Stand des Submodules vendor/executor.
ARG EXECUTOR_REF=d4bed30d2f059e3e29a42a4451ddc5eebbfebd08
ARG EXECUTOR_REPO=https://github.com/flaqship/qc-executor.git

# Nicht-root-User. 1000 passt fuer die meisten Linux-Hosts; auf Docker Desktop
# (Windows/macOS) spielt der Wert keine Rolle.
ARG UID=1000
ARG GID=1000

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    MPLBACKEND=Agg \
    PYTHONPATH=/app

WORKDIR /app

# git wird nur fuer "pip install git+https://..." gebraucht.
RUN apt-get update \
    && apt-get install -y --no-install-recommends git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt ./
RUN pip install -r requirements.txt \
    && pip install "qc-executor @ git+${EXECUTOR_REPO}@${EXECUTOR_REF}"

RUN groupadd --gid "${GID}" bench \
    && useradd --uid "${UID}" --gid "${GID}" --create-home bench

# Code ins Image kopieren, damit es auch ohne Volume-Mount lauffaehig ist.
# Ausgabeordner vorab anlegen und dem User geben.
COPY benchmarks/ ./benchmarks/
COPY plot_forms/ ./plot_forms/
RUN mkdir -p raw_results final_plotted_results \
    && chown -R bench:bench /app

USER bench

ENTRYPOINT ["python"]
# Standard: kurzer Lauf, der in wenigen Minuten fertig ist.
CMD ["benchmarks/pennylane_benchmark.py", "--qubits", "5", "--mode", "all", "--max-gates", "200", "--repeats", "1"]
