#include "inference_engine.hpp"
#include <algorithm>
#include <cmath>
#include <fstream>
#include <iostream>

#ifdef _WIN32
    #include <windows.h>
#endif

namespace LLM {

void MatrixOps::matmul_cpu(const float* A, const float* B, float* C,
                           int M, int N, int K) {
    #pragma omp parallel for collapse(2)
    for (int i = 0; i < M; ++i) {
        for (int j = 0; j < N; ++j) {
            float sum = 0.0f;
            for (int k = 0; k < K; ++k) {
                sum += A[i * K + k] * B[k * N + j];
            }
            C[i * N + j] = sum;
        }
    }
}

void MatrixOps::matmul_gpu(const float* A, const float* B, float* C,
                          int M, int N, int K) {
    #ifdef USE_CUDA
        cublasHandle_t handle;
        cublasCreate(&handle);
        
        float alpha = 1.0f, beta = 0.0f;
        cublasSgemm(handle, CUBLAS_OP_N, CUBLAS_OP_N,
                   N, M, K, &alpha,
                   B, N, A, K, &beta, C, N);
        
        cublasDestroy(handle);
    #endif
}

void MatrixOps::softmax_cpu(float* data, int size) {
    float max_val = *std::max_element(data, data + size);
    
    float sum = 0.0f;
    #pragma omp parallel for reduction(+:sum)
    for (int i = 0; i < size; ++i) {
        data[i] = std::exp(data[i] - max_val);
        sum += data[i];
    }
    
    #pragma omp parallel for
    for (int i = 0; i < size; ++i) {
        data[i] /= sum;
    }
}

void MatrixOps::softmax_gpu(float* data, int size) {
    #ifdef USE_CUDA
        cudnnHandle_t handle;
        cudnnCreate(&handle);
        
        cudnnTensorDescriptor_t desc;
        cudnnCreateTensorDescriptor(&desc);
        cudnnSetTensor4dDescriptor(desc, CUDNN_TENSOR_NCHW, CUDNN_DATA_FLOAT,
                                  1, 1, 1, size);
        
        float alpha = 1.0f, beta = 0.0f;
        cudnnSoftmaxForward(handle, CUDNN_SOFTMAX_ACCURATE, CUDNN_SOFTMAX_MODE_INSTANCE,
                           &alpha, desc, data,
                           &beta, desc, data);
        
        cudnnDestroyTensorDescriptor(desc);
        cudnnDestroy(handle);
    #endif
}

LLMInferenceEngine::LLMInferenceEngine(Backend backend)
    : backend_(backend) {
    
    std::cout << "LLM Inference Engine initialized" << std::endl;
    std::cout << "Device Info: " << get_device_info() << std::endl;
}

LLMInferenceEngine::~LLMInferenceEngine() {
    for (auto& tensor : weights_) {
        if (tensor.on_gpu && tensor.gpu_ptr) {
            GPUMemory::instance().deallocate(tensor.gpu_ptr);
        }
    }
}

bool LLMInferenceEngine::load_model(const std::string& model_path) {
    try {
        std::ifstream file(model_path, std::ios::binary);
        if (!file.is_open()) {
            std::cerr << "Failed to open model file: " << model_path << std::endl;
            return false;
        }
        
        uint32_t num_layers;
        file.read(reinterpret_cast<char*>(&num_layers), sizeof(uint32_t));
        
        for (uint32_t i = 0; i < num_layers; ++i) {
            uint32_t w_size, h_size;
            file.read(reinterpret_cast<char*>(&w_size), sizeof(uint32_t));
            file.read(reinterpret_cast<char*>(&h_size), sizeof(uint32_t));
            
            Tensor weight;
            weight.shape = {(int)w_size, (int)h_size};
            weight.data.resize(w_size * h_size);
            
            file.read(reinterpret_cast<char*>(weight.data.data()), 
                     w_size * h_size * sizeof(float));
            
            if (backend_ == GPU_CUDA) {
                weight.gpu_ptr = GPUMemory::instance().allocate(
                    w_size * h_size * sizeof(float));
                GPUMemory::instance().copy_to_gpu(
                    weight.gpu_ptr, weight.data.data(),
                    w_size * h_size * sizeof(float));
                weight.on_gpu = true;
            }
            
            weights_.push_back(weight);
        }
        
        std::cout << "Model loaded: " << num_layers << " layers" << std::endl;
        return true;
    } catch (const std::exception& e) {
        std::cerr << "Model loading error: " << e.what() << std::endl;
        return false;
    }
}

Tensor LLMInferenceEngine::forward_pass(const Tensor& input) {
    Tensor output = input;
    
    for (const auto& weight : weights_) {
        Tensor intermediate;
        intermediate.shape = {weight.shape[0], 1};
        intermediate.data.resize(weight.shape[0]);
        
        if (backend_ == GPU_CUDA && weight.on_gpu) {
            MatrixOps::matmul_gpu(input.data.data(), weight.data.data(),
                                 intermediate.data.data(),
                                 input.shape[0], weight.shape[0], input.shape[1]);
        } else {
            MatrixOps::matmul_cpu(input.data.data(), weight.data.data(),
                                 intermediate.data.data(),
                                 input.shape[0], weight.shape[0], input.shape[1]);
        }
        
        MatrixOps::softmax_cpu(intermediate.data.data(), intermediate.data.size());
        output = intermediate;
    }
    
    return output;
}

std::vector<int> LLMInferenceEngine::tokenize(const std::string& text) {
    std::vector<int> tokens;
    for (char c : text) {
        tokens.push_back(static_cast<unsigned char>(c));
    }
    return tokens;
}

std::string LLMInferenceEngine::detokenize(const std::vector<int>& tokens) {
    std::string text;
    for (int token : tokens) {
        if (token < 256) {
            text += static_cast<char>(token);
        }
    }
    return text;
}

std::string LLMInferenceEngine::generate(const std::string& prompt,
                                        int max_tokens,
                                        float temperature) {
    auto tokens = tokenize(prompt);
    std::string result = prompt;
    
    for (int i = 0; i < max_tokens; ++i) {
        std::vector<float> input_data(tokens.begin(), tokens.end());
        
        for (auto& val : input_data) {
            val /= 255.0f;
        }
        
        Tensor input;
        input.data = input_data;
        input.shape = {1, (int)input_data.size()};
        
        Tensor output = forward_pass(input);
        
        float max_logit = *std::max_element(output.data.begin(), output.data.end());
        int next_token = std::max_element(output.data.begin(), output.data.end()) 
                        - output.data.begin();
        
        tokens.push_back(next_token);
        result += (char)next_token;
    }
    
    return result;
}

std::string LLMInferenceEngine::get_device_info() const {
    std::string info = "CPU (";
    
    #ifdef _WIN32
        #ifdef USE_CUDA
            info += "CUDA";
            int device_count;
            cudaGetDeviceCount(&device_count);
            info += " - " + std::to_string(device_count) + " GPU(s)";
        #else
            info += "CPU only";
        #endif
    #else
        info += "Metal GPU";
    #endif
    
    info += ")";
    return info;
}

}
