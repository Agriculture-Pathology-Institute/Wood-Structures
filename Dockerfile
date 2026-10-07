# Use a lightweight Python base image packaged with standard NVIDIA CUDA toolkit runtimes
FROM nvidia/cuda:12.2.0-base-ubuntu22.04

# Install basic environment dependencies and C-level compiler bindings
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Ingest and cache execution module libraries
RUN pip3 install --no-cache-dir \
    numba \
    numpy \
    pyyaml

# Map project files into core execution layers
COPY src/ /app/src/

# Define baseline environment entry space properties
ENV NUMBA_CACHE_DIR=/tmp/numba_cache
