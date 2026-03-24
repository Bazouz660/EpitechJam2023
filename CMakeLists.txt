cmake_minimum_required(VERSION 3.16)
project(nerdSimulator 
    VERSION 1.0.0
    DESCRIPTION "A nerd-themed puzzle game"
    LANGUAGES CXX
)

# Set C++ standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Set output directories for multi-config generators (MSVC, Xcode)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")

# Find required packages
find_package(SFML 2.5 COMPONENTS graphics window system audio REQUIRED)

# Include directories
include_directories("${CMAKE_SOURCE_DIR}/include")

# Recursively add header subdirectories
file(GLOB_RECURSE HEADER_FILES "${CMAKE_SOURCE_DIR}/src/*.hpp")
foreach(HEADER_FILE ${HEADER_FILES})
    get_filename_component(HEADER_DIR ${HEADER_FILE} DIRECTORY)
    include_directories(${HEADER_DIR})
endforeach()

# Collect source files
file(GLOB_RECURSE SOURCE_FILES "${CMAKE_SOURCE_DIR}/src/*.cpp")

# Create executable
add_executable(${PROJECT_NAME} ${SOURCE_FILES})

# Link libraries
target_link_libraries(${PROJECT_NAME} 
    PRIVATE 
        sfml-graphics 
        sfml-window 
        sfml-system 
        sfml-audio
)

# Compiler-specific flags for better warnings
if(MSVC)
    target_compile_options(${PROJECT_NAME} PRIVATE /W4 /WX)
else()
    target_compile_options(${PROJECT_NAME} PRIVATE -Wall -Wextra -Wpedantic)
endif()

# Add version information
target_compile_definitions(${PROJECT_NAME} PRIVATE 
    APP_VERSION="${PROJECT_VERSION}"
)

# Display build information
message(STATUS "Building ${PROJECT_NAME} v${PROJECT_VERSION}")
message(STATUS "C++ Standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "SFML found at: ${SFML_INCLUDE_DIR}")
