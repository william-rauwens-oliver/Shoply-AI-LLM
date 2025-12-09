#pragma once

#include <vector>
#include <string>
#include <memory>
#include <stdexcept>

#ifdef _WIN32
    #include <cuda_runtime.h>
    #include <cudnn.h>
    #define USE_CUDA 1
#else
    #include <metal_cpp/metal.hpp>
    #define USE_METAL 1
#endif

namespace LLM {

struct Tensor {
    std::vector<float> data;
    std::vector<int> shape;
    bool on_gpu = false;
    void* gpu_ptr = nullptr;
    
    size_t total_elements() const {
        size_t total = 1;
        for (int s : shape) total *= s;
        return total;
    }
};

class GPUMemory {
public:
    static GPUMemory& instance() {
        static GPUMemory inst;
        return inst;
    }
    
    void* allocate(size_t bytes) {
        #ifdef USE_CUDA
            void* ptr;
            cudaMalloc(&ptr, bytes);
            return ptr;
        #else
            return malloc(bytes);
        #endif
    }
    
    void deallocate(void* ptr) {
        #ifdef USE_CUDA
            cudaFree(ptr);
        #else
            free(ptr);
        #endif
    }
    
    void copy_to_gpu(void* gpu_ptr, const void* cpu_ptr, size_t bytes) {
        #ifdef USE_CUDA
            cudaMemcpy(gpu_ptr, cpu_ptr, bytes, cudaMemcpyHostToDevice);
        #endif
    }
    
    void copy_from_gpu(void* cpu_ptr, const void* gpu_ptr, size_t bytes) {
        #ifdef USE_CUDA
            cudaMemcpy(cpu_ptr, gpu_ptr, bytes, cudaMemcpyDeviceToHost);
        #endif
    }

private:
    GPUMemory() = default;
};

class MatrixOps {
public:
    static void matmul_cpu(const float* A, const float* B, float* C,
                           int M, int N, int K);
    
    static void matmul_gpu(const float* A, const float* B, float* C,
                          int M, int N, int K);
    
    static void softmax_cpu(float* data, int size);
    
    static void softmax_gpu(float* data, int size);
};

class LLMInferenceEngine {
public:
    enum Backend { CPU, GPU_CUDA, GPU_METAL };
    
    LLMInferenceEngine(Backend backend = CPU);
    ~LLMInferenceEngine();
    
    bool load_model(const std::string& model_path);
    
    std::string generate(const std::string& prompt, 
                        int max_tokens = 80,
                        float temperature = 0.8f);
    
    void set_backend(Backend b) { backend_ = b; }
    
    std::string get_device_info() const;
    
private:
    Backend backend_;
    std::vector<Tensor> weights_;
    std::vector<Tensor> activations_;
    
    Tensor forward_pass(const Tensor& input);
    std::vector<int> tokenize(const std::string& text);
    std::string detokenize(const std::vector<int>& tokens);
};

}
