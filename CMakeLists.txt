cmake_minimum_required(VERSION 3.20)
project(LLMChat)

set(CMAKE_CXX_STANDARD 17)

# Platform-specific builds
if(WIN32)
    # C++ implementation with CUDA support
    add_subdirectory(native/windows/cpp)
    
    # Optional: C implementation for pure Windows API reference
    # Uncomment to build C version alongside C++
    # add_executable(llm_chat_c native/windows/c/llm_chat.c)
    # target_link_libraries(llm_chat_c PRIVATE user32 gdi32 kernel32)
    
elseif(APPLE)
    # macOS Swift implementation
    message(STATUS "macOS detected - use Swift Package Manager")
    message(STATUS "  cd native/macos && swift build -c release")
    
else()
    message(STATUS "Unsupported platform")
endif()

# Info message
message(STATUS "")
message(STATUS "=== LLM Chat Build Configuration ===")
message(STATUS "Platform: ${CMAKE_SYSTEM_NAME}")
message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "C++ Compiler: ${CMAKE_CXX_COMPILER}")
message(STATUS "=====================================")
message(STATUS "")
