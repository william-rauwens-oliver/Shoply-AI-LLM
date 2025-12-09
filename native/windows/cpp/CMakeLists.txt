cmake_minimum_required(VERSION 3.20)
project(LLMChatCPP LANGUAGES CXX CUDA)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# GPU Detection
if(WIN32)
    find_package(CUDA QUIET)
    if(CUDA_FOUND)
        set(GPU_SUPPORT ON)
        set(CUDA_NVCC_FLAGS "${CUDA_NVCC_FLAGS} -gencode arch=compute_75,code=sm_75")
        message(STATUS "CUDA found: ${CUDA_TOOLKIT_ROOT_DIR}")
    else()
        set(GPU_SUPPORT OFF)
        message(STATUS "CUDA not found, building CPU-only version")
    endif()
endif()

# Main executable
add_executable(llm_chat_cpp
    cpp/main.cpp
    cpp/gui.cpp
    cpp/inference_engine.cpp
)

# Include directories
target_include_directories(llm_chat_cpp PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/cpp
)

# Windows API
if(WIN32)
    target_link_libraries(llm_chat_cpp PRIVATE
        user32
        gdi32
        kernel32
    )
    
    # GPU acceleration if available
    if(GPU_SUPPORT)
        target_compile_definitions(llm_chat_cpp PRIVATE
            GPU_ENABLED=1
            USE_CUDA=1
        )
        target_link_libraries(llm_chat_cpp PRIVATE
            ${CUDA_LIBRARIES}
            cublas
            cudnn
        )
        target_include_directories(llm_chat_cpp PRIVATE
            ${CUDA_INCLUDE_DIRS}
        )
    endif()
    
    # Assembly optimization
    enable_language(ASM_MASM)
    set(CMAKE_ASM_MASM_FLAGS "${CMAKE_ASM_MASM_FLAGS} /Zi")
    
    add_library(matrix_ops_asm
        asm/matrix_ops.asm
    )
    
    set_target_properties(matrix_ops_asm PROPERTIES
        LANGUAGE ASM_MASM
    )
    
    target_link_libraries(llm_chat_cpp PRIVATE matrix_ops_asm)
endif()

# Optimization flags
if(MSVC)
    target_compile_options(llm_chat_cpp PRIVATE
        /O2 /Oi /Ot /GL /fp:fast
    )
    set_target_properties(llm_chat_cpp PROPERTIES
        LINK_FLAGS "/LTCG"
    )
else()
    target_compile_options(llm_chat_cpp PRIVATE
        -O3 -march=native -ffast-math
    )
endif()

# Set startup project for Visual Studio
if(MSVC)
    set_property(DIRECTORY PROPERTY VS_STARTUP_PROJECT llm_chat_cpp)
endif()

message(STATUS "GPU Support: ${GPU_SUPPORT}")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
