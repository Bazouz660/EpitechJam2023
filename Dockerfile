# Multi-stage build Dockerfile for cross-platform SFML project
# Supports: Linux (native), Windows/macOS (with Docker Desktop or WSL2)

FROM ubuntu:22.04

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV CMAKE_BUILD_TYPE=Release

# Install build essentials and dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    pkg-config \
    libsfml-dev \
    libx11-dev \
    libxrandr-dev \
    libxcb-randr0-dev \
    libxcb-icccm4-dev \
    libxcb-image0-dev \
    libxcb-keysyms1-dev \
    libxcb-shape0-dev \
    libxcb-xfixes0-dev \
    libxcb-xinerama0-dev \
    libxcb-xkb-dev \
    libxkbcommon-dev \
    libxkbcommon-x11-dev \
    libfreetype6-dev \
    libudev-dev \
    libogg-dev \
    libvorbis-dev \
    libflac-dev \
    libopenal-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /project

# Copy project files into container
COPY . .

# Create build directory
RUN mkdir -p build

# Configure and build the project
RUN cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release .. && \
    cmake --build . --config Release

# Set the default command (can be overridden)
CMD ["/project/build/bin/nerdSimulator"]
