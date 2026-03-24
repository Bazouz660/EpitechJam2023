#!/bin/bash
# Cross-platform build script for nerdSimulator
# Usage: ./build.sh [build|run|clean]

set -e

COMMAND=${1:-build}
IMAGE_NAME="nerd-simulator:latest"
WIN_IMAGE_NAME="nerd-simulator-win-builder:latest"
CONTAINER_NAME="nerd-simulator-build"
CONTAINER_RUNTIME=${CONTAINER_RUNTIME:-podman}

ensure_linux_image() {
    if ! $CONTAINER_RUNTIME image exists "$IMAGE_NAME" 2>/dev/null; then
        echo "Building Linux image ($IMAGE_NAME)..."
        $CONTAINER_RUNTIME build -t "$IMAGE_NAME" .
    fi
}

case "$COMMAND" in
    build)
        ensure_linux_image
        echo "Building project inside container with volume mounts..."
        mkdir -p build
        $CONTAINER_RUNTIME run --rm \
            -v "$(pwd)/src:/project/src" \
            -v "$(pwd)/include:/project/include" \
            -v "$(pwd)/asset:/project/asset" \
            -v "$(pwd)/CMakeLists.txt:/project/CMakeLists.txt" \
            -v "$(pwd)/build:/project/build" \
            -w /project \
            $IMAGE_NAME \
            bash -c "mkdir -p build && cd build && cmake -DCMAKE_BUILD_TYPE=Release .. && cmake --build . --config Release"
        if [ $? -eq 0 ]; then
            echo "✓ Build successful! Binary at: ./build/bin/nerdSimulator"
        else
            echo "✗ Build failed!"
            exit 1
        fi
        ;;
    
    run)
        ensure_linux_image
        echo "Building and running nerd-simulator..."
        # First build the project
        $0 build
        if [ -f "./build/bin/nerdSimulator" ]; then
            echo "Running the game..."
            $CONTAINER_RUNTIME run --rm -it \
                -v "$(pwd)/asset:/project/asset" \
                -v "$(pwd)/scores:/project/scores" \
                -v "$(pwd)/build:/project/build" \
                $IMAGE_NAME /project/build/bin/nerdSimulator
        else
            echo "✗ Binary not found. Build may have failed."
            exit 1
        fi
        ;;
    
    rebuild)
        echo "Rebuilding from scratch..."
        rm -rf build
        mkdir -p build
        $0 build
        ;;
    
    clean)
        echo "Cleaning $CONTAINER_RUNTIME artifacts..."
        $CONTAINER_RUNTIME image rm $IMAGE_NAME 2>/dev/null || echo "Image not found"
        $CONTAINER_RUNTIME image rm $WIN_IMAGE_NAME 2>/dev/null || echo "Windows image not found"
        $CONTAINER_RUNTIME container rm $CONTAINER_NAME 2>/dev/null || echo "Container not found"
        $CONTAINER_RUNTIME container rm nerd-sim-run 2>/dev/null || echo "Run container not found"
        echo "✓ Cleanup complete!"
        ;;
    
    shell)
        ensure_linux_image
        echo "Starting interactive shell in container..."
        $CONTAINER_RUNTIME run --rm -it \
            -v "$(pwd)/src:/project/src" \
            -v "$(pwd)/include:/project/include" \
            -v "$(pwd)/asset:/project/asset" \
            -v "$(pwd)/CMakeLists.txt:/project/CMakeLists.txt" \
            -v "$(pwd)/build:/project/build" \
            -w /project \
            $IMAGE_NAME bash
        ;;

    win-build)
        echo "Building Windows toolchain image..."
        $CONTAINER_RUNTIME build -f Dockerfile.windows -t $WIN_IMAGE_NAME .
        echo "Cross-compiling Windows executable..."
        mkdir -p build-win
        $CONTAINER_RUNTIME run --rm \
            -v "$(pwd)/src:/project/src" \
            -v "$(pwd)/include:/project/include" \
            -v "$(pwd)/asset:/project/asset" \
            -v "$(pwd)/CMakeLists.txt:/project/CMakeLists.txt" \
            -v "$(pwd)/cmake:/project/cmake" \
            -v "$(pwd)/build-win:/project/build-win" \
            -w /project \
            $WIN_IMAGE_NAME \
            bash -lc "cmake -S . -B build-win -G 'Unix Makefiles' -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=/project/cmake/toolchains/mingw-w64-x86_64.cmake -DCMAKE_PREFIX_PATH=/opt/mingw-sfml && cmake --build build-win --config Release && cp -f /opt/mingw-sfml/bin/*.dll build-win/bin/ 2>/dev/null || true && cp -f /usr/lib/gcc/x86_64-w64-mingw32/10-win32/libstdc++-6.dll build-win/bin/ && cp -f /usr/lib/gcc/x86_64-w64-mingw32/10-win32/libgcc_s_seh-1.dll build-win/bin/ && cp -f /usr/x86_64-w64-mingw32/lib/libwinpthread-1.dll build-win/bin/"
        if [ -f "./build-win/bin/nerdSimulator.exe" ]; then
            echo "✓ Windows build successful: ./build-win/bin/nerdSimulator.exe"
            cp -f ./build-win/bin/nerdSimulator.exe ./nerdSimulator.exe
            cp -f ./build-win/bin/*.dll ./ 2>/dev/null || true
            echo "✓ Staged run files in repo root: ./nerdSimulator.exe + DLLs"
        else
            echo "✗ Windows build failed"
            exit 1
        fi
        ;;

    win-rebuild)
        echo "Rebuilding Windows target from scratch..."
        rm -rf build-win
        mkdir -p build-win
        $0 win-build
        ;;

    win-shell)
        echo "Starting shell in Windows builder container..."
        $CONTAINER_RUNTIME run -it --rm \
            -v "$(pwd):/project" \
            -w /project \
            $WIN_IMAGE_NAME bash
        ;;
    
    *)
        echo "Usage: $0 {build|run|rebuild|clean|shell|win-build|win-rebuild|win-shell}"
        echo ""
        echo "Commands:"
        echo "  build    - Build the project (with volume mounts)"
        echo "  run      - Build and run the application"
        echo "  rebuild  - Clean rebuild"
        echo "  clean    - Remove image and containers"
        echo "  shell    - Start interactive bash shell"
        echo "  win-build   - Build native Windows .exe"
        echo "  win-rebuild - Clean rebuild native Windows .exe"
        echo "  win-shell   - Start shell in Windows builder image"
        echo ""
        echo "Environment:"
        echo "  CONTAINER_RUNTIME - Set to 'docker' or 'podman' (default: podman)"
        exit 1
        ;;
esac
