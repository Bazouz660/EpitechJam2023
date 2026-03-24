# Cross-Platform Build Guide

This project uses **containerized builds with volume mounts** - no dependencies on your system, but the binary is built on your local filesystem.

## Prerequisites

- **Podman** installed ([Download Podman](https://podman.io/docs/installation)) - OR **Docker** if preferred
- **Git** (for cloning the repository)

## Quick Start

### Using Helper Scripts (Recommended)

**Linux/macOS:**
```bash
chmod +x build.sh

./build.sh build        # Build the project → ./build/bin/nerdSimulator
./build.sh run          # Build and run the game
./build.sh rebuild      # Clean rebuild
./build.sh shell        # Interactive development shell
./build.sh clean        # Remove containers/images
```

**Windows (PowerShell):**
```powershell
.\build.ps1 build       # Build the project → ./build/bin/nerdSimulator
.\build.ps1 run         # Build and run the game
.\build.ps1 rebuild     # Clean rebuild
.\build.ps1 shell       # Interactive development shell
.\build.ps1 clean       # Remove containers/images
```

### Manual Build with Podman

```bash
# 1. Build the container image (one time only)
podman build -t nerd-simulator:latest .

# 2. Build your project (binary goes to local ./build/bin/)
mkdir -p build
podman run --rm \
    -v $(pwd)/src:/project/src \
    -v $(pwd)/include:/project/include \
    -v $(pwd)/asset:/project/asset \
    -v $(pwd)/CMakeLists.txt:/project/CMakeLists.txt \
    -v $(pwd)/build:/project/build \
    -w /project \
    nerd-simulator:latest \
    bash -c "mkdir -p build && cd build && cmake -DCMAKE_BUILD_TYPE=Release .. && cmake --build . --config Release"

# 3. Run the binary (if on Linux/macOS with native execution)
./build/bin/nerdSimulator
```

## How Volume Mounts Work

Volume mounts connect directories from your computer into the container:

| Host | Container | Purpose |
|------|-----------|---------|
| `./src` | `/project/src` | Source code |
| `./include` | `/project/include` | Header files |
| `./build` | `/project/build` | **Build output (your binary ends up here)** |
| `./asset` | `/project/asset` | Game resources |
| `CMakeLists.txt` | `/project/CMakeLists.txt` | Build configuration |

When the container builds, the binary is written directly to `./build/bin/nerdSimulator` on your **local** filesystem.

## Running the Game

### On Linux/macOS (Native Execution)
The binary is compiled for Linux, so you can run it directly:
```bash
./build/bin/nerdSimulator
```

### On Windows
Windows cannot execute Linux binaries natively. Options:

**Option A: Use WSL2 (Windows Subsystem for Linux)**
```powershell
# From WSL2 terminal:
./build/bin/nerdSimulator
```

**Option B: Run in Container**
```powershell
.\build.ps1 run    # Builds and runs in container
```

**Option C: Build Native Windows .exe (implemented)**
```powershell
.\build.ps1 win-build      # Build native Windows executable
.\build.ps1 win-rebuild    # Clean rebuild native Windows executable

# Output:
# .\build-win\bin\nerdSimulator.exe
```

## Development Workflow

### Interactive Development

Start an interactive shell inside the container:
```bash
./build.sh shell    # Linux/macOS
.\build.ps1 shell   # Windows
```

Inside the shell:
```bash
cd /project/build
cmake ..
cmake --build . -- -j$(nproc)  # Rebuild incrementally

# Changes to source code are live-reflected since directories are mounted
```

### Quick Rebuild

```bash
./build.sh build    # Rebuilds only the project (not the image)
```

## Platform-Specific Instructions

### Windows (with Podman)
1. Install Podman Desktop for Windows
2. Use PowerShell or Git Bash to run commands
3. For WSL2 backend: Run commands similar to Linux

### macOS (with Podman)
1. Install Podman via Homebrew: `brew install podman`
2. Optionally install Podman Desktop: `brew install podman-desktop`
3. Run commands in Terminal

### Linux (with Podman)
1. Install Podman: `apt install podman` (Ubuntu/Debian) or `dnf install podman` (Fedora)
2. No daemon startup needed (unlike Docker)
3. For GUI rendering (if needed):
   - Use rootless Podman with proper X11 socket mounting
   - Or build in container and run game on host

## Development Workflow

### Interactive Development Build (Podman)

```bash
# Start a bash shell inside a container
podman run -it -v $(pwd):/project -w /project nerd-simulator:latest bash

# Inside the container:
cd /project/build
cmake ..
cmake --build . -- -j$(nproc)
```

### Using Helper Scripts

**Linux/macOS:**
```bash
# Make scripts executable
chmod +x build.sh

# Build
./build.sh build

# Run
./build.sh run

# Interactive shell
./build.sh shell

# Clean up
./build.sh clean

# Force rebuild without cache
./build.sh rebuild
```

Set environment to use Docker instead:
```bash
CONTAINER_RUNTIME=docker ./build.sh build
```

**Windows (PowerShell):**
```powershell
# Build
.\build.ps1 build

# Run
.\build.ps1 run

# Interactive shell
.\build.ps1 shell

# Clean up
.\build.ps1 clean

# Force rebuild
.\build.ps1 rebuild

# Use Docker instead of Podman
$env:CONTAINER_RUNTIME="docker"; .\build.ps1 build
```

### Rebuild Only (Without Full Image Rebuild)

```bash
podman run -v $(pwd):/project -w /project nerd-simulator:latest \
  bash -c "cd build && cmake --build ."
```

### Mount Source for Live Development

```bash
podman run -it -v $(pwd):/project -w /project nerd-simulator:latest bash
```

## Build Troubleshooting

### "Podman/Docker not found"
- **Windows**: Ensure Podman Desktop is installed and running
- **macOS**: Reinstall with `brew reinstall podman`
- **Linux**: Install with your package manager

### Permission Denied (Linux)
- Podman in rootless mode doesn't need sudo
- If using Docker: `sudo usermod -aG docker $USER` and log back in

### X11 Display Issues on Linux
- Podman doesn't easily expose graphical output
- Build in container, run game executable on host system
- Or use Docker with `--display=$DISPLAY` binding

### GPU Rendering Issues
- For GPU support with Podman, use: `podman run --device=/dev/kfd --device=/dev/dri ...`
- For Docker, use: `docker run --gpus all ...`

## Clean Build

To remove build artifacts and rebuild from scratch:

```bash
# With Podman
podman-compose down -v  # If using compose
podman image rm nerd-simulator:latest
podman-compose build --no-cache

# With Docker
docker-compose down -v
docker image rm nerd-simulator:latest
docker-compose build --no-cache
```

## CI/CD Integration

These containers work seamlessly with GitHub Actions, GitLab CI, and other CI/CD systems for automatic cross-platform builds without managing system dependencies.

## Podman vs Docker

| Feature | Podman | Docker |
|---------|--------|--------|
| Daemon Required | No 🎯 | Yes |
| Rootless Mode | Native | Limited |
| Installation | Lightweight | Heavier |
| Compatibility | Docker-compatible | Standard |
| Performance | Similar | Similar |
| Security Model | Better isolation | Standard |

## Notes

- The project compiles to `/project/build/nerdSimulator` inside the container
- Asset and score files are preserved in mounted volumes
- Build artifacts are cached for faster rebuilds
- Both Podman and Docker can be used interchangeably with these scripts
