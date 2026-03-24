# Cross-platform build script for nerdSimulator (PowerShell)
# Usage: .\build.ps1 -Command build

param(
    [Parameter(Position = 0)]
    [ValidateSet("build", "run", "rebuild", "clean", "shell", "win-build", "win-rebuild", "win-shell")]
    [string]$Command = "build",
    
    [string]$ContainerRuntime = $env:CONTAINER_RUNTIME
)

# Default to podman if not specified
if (-not $ContainerRuntime) {
    $ContainerRuntime = "podman"
}

$ImageName = "nerd-simulator:latest"
$WinImageName = "nerd-simulator-win-builder:latest"
$ContainerName = "nerd-simulator-build"
$ProjectRoot = (Get-Location).Path

function Build-Image {
    Write-Host "Building image with $ContainerRuntime..." -ForegroundColor Cyan
    & $ContainerRuntime build -t $ImageName .
    Write-Host "Build complete! Image: $ImageName" -ForegroundColor Green
}

function Build-Project {
    Write-Host "Building project inside container with volume mounts..." -ForegroundColor Cyan
    # Ensure build directory exists
    if (-not (Test-Path "build")) {
        New-Item -ItemType Directory -Path "build" -Force | Out-Null
    }
    # Run build in container with mounted source and build directories
    & $ContainerRuntime run --rm `
        -v "${ProjectRoot}/src:/project/src" `
        -v "${ProjectRoot}/include:/project/include" `
        -v "${ProjectRoot}/asset:/project/asset" `
        -v "${ProjectRoot}/CMakeLists.txt:/project/CMakeLists.txt" `
        -v "${ProjectRoot}/build:/project/build" `
        -w /project `
        $ImageName `
        bash -c "mkdir -p build && cd build && cmake -DCMAKE_BUILD_TYPE=Release .. && cmake --build . --config Release"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Build successful! Binary at: ./build/bin/nerdSimulator" -ForegroundColor Green
    } else {
        Write-Host "Build failed!" -ForegroundColor Red
    }
}

function Build-WinImage {
    Write-Host "Building Windows toolchain image with $ContainerRuntime..." -ForegroundColor Cyan
    & $ContainerRuntime build -f Dockerfile.windows -t $WinImageName .
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Windows builder image ready: $WinImageName" -ForegroundColor Green
    } else {
        Write-Host "Failed to build Windows builder image" -ForegroundColor Red
    }
}

function Build-WinProject {
    Write-Host "Cross-compiling native Windows executable..." -ForegroundColor Cyan
    if (-not (Test-Path "build-win")) {
        New-Item -ItemType Directory -Path "build-win" -Force | Out-Null
    }

    Build-WinImage
    if ($LASTEXITCODE -ne 0) {
        return
    }

    & $ContainerRuntime run --rm `
        -v "${ProjectRoot}/src:/project/src" `
        -v "${ProjectRoot}/include:/project/include" `
        -v "${ProjectRoot}/asset:/project/asset" `
        -v "${ProjectRoot}/CMakeLists.txt:/project/CMakeLists.txt" `
        -v "${ProjectRoot}/cmake:/project/cmake" `
        -v "${ProjectRoot}/build-win:/project/build-win" `
        -w /project `
        $WinImageName `
        bash -lc "cmake -S . -B build-win -G 'Unix Makefiles' -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=/project/cmake/toolchains/mingw-w64-x86_64.cmake -DCMAKE_PREFIX_PATH=/opt/mingw-sfml && cmake --build build-win --config Release && cp -f /opt/mingw-sfml/bin/*.dll build-win/bin/ 2>/dev/null || true && cp -f /usr/lib/gcc/x86_64-w64-mingw32/10-win32/libstdc++-6.dll build-win/bin/ && cp -f /usr/lib/gcc/x86_64-w64-mingw32/10-win32/libgcc_s_seh-1.dll build-win/bin/ && cp -f /usr/x86_64-w64-mingw32/lib/libwinpthread-1.dll build-win/bin/"

    if (Test-Path "./build-win/bin/nerdSimulator.exe") {
        Write-Host "Windows build successful: ./build-win/bin/nerdSimulator.exe" -ForegroundColor Green
        Copy-Item -Force "./build-win/bin/nerdSimulator.exe" "${ProjectRoot}/nerdSimulator.exe"
        Get-ChildItem "./build-win/bin/*.dll" -ErrorAction SilentlyContinue | ForEach-Object {
            Copy-Item -Force $_.FullName "${ProjectRoot}/$($_.Name)"
        }
        Write-Host "Staged run files in repo root: ./nerdSimulator.exe + DLLs" -ForegroundColor Green
    } else {
        Write-Host "Windows binary not found. Build failed." -ForegroundColor Red
    }
}

function Rebuild-WinProject {
    Write-Host "Rebuilding Windows target from scratch..." -ForegroundColor Cyan
    if (Test-Path "build-win") {
        Remove-Item -Recurse -Force -Path "build-win" -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path "build-win" -Force | Out-Null
    Build-WinProject
}

function Run-Container {
    Write-Host "Building and running nerd-simulator..." -ForegroundColor Cyan
    # First build the project with volume mounts
    Build-Project
    # Then run it
    if (Test-Path "./build/bin/nerdSimulator") {
        Write-Host "Running the game..." -ForegroundColor Cyan
        & $ContainerRuntime run -it --name nerd-sim-run `
            -v "${ProjectRoot}/asset:/project/asset" `
            -v "${ProjectRoot}/scores:/project/scores" `
            -v "${ProjectRoot}/build:/project/build" `
            $ImageName /project/build/bin/nerdSimulator
    } else {
        Write-Host "Binary not found. Build may have failed." -ForegroundColor Red
    }
}

function Rebuild-Image {
    Write-Host "Rebuilding project from scratch (no cache)..." -ForegroundColor Cyan
    if (Test-Path "build") {
        Remove-Item -Recurse -Force -Path "build" -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path "build" -Force | Out-Null
    Build-Project
}

function Clean {
    Write-Host "Cleaning $ContainerRuntime artifacts..." -ForegroundColor Cyan
    & $ContainerRuntime image rm $ImageName -ErrorAction SilentlyContinue
    & $ContainerRuntime container rm $ContainerName -ErrorAction SilentlyContinue
    Write-Host "Cleanup complete!" -ForegroundColor Green
}

function Start-Shell {
    Write-Host "Starting interactive shell in container..." -ForegroundColor Cyan
    & $ContainerRuntime run -it `
        -v "${ProjectRoot}/src:/project/src" `
        -v "${ProjectRoot}/include:/project/include" `
        -v "${ProjectRoot}/asset:/project/asset" `
        -v "${ProjectRoot}/CMakeLists.txt:/project/CMakeLists.txt" `
        -v "${ProjectRoot}/build:/project/build" `
        -w /project `
        $ImageName /bin/bash
}

function Start-WinShell {
    Write-Host "Starting interactive shell in Windows builder container..." -ForegroundColor Cyan
    & $ContainerRuntime run -it --rm `
        -v "${ProjectRoot}:/project" `
        -w /project `
        $WinImageName bash
}

Write-Host "Using container runtime: $ContainerRuntime" -ForegroundColor Gray

switch ($Command) {
    "build" { Build-Project }
    "run" { Run-Container }
    "rebuild" { Rebuild-Image }
    "clean" { Clean }
    "shell" { Start-Shell }
    "win-build" { Build-WinProject }
    "win-rebuild" { Rebuild-WinProject }
    "win-shell" { Start-WinShell }
}

