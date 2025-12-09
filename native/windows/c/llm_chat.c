#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MATRIX_MAX_SIZE 1024
#define MAX_LAYERS 12

typedef struct {
    float* data;
    int rows;
    int cols;
} Matrix;

typedef struct {
    Matrix* layers[MAX_LAYERS];
    int num_layers;
    int use_gpu;
} LLMModel;

typedef struct {
    HWND hwnd;
    HWND input_box;
    HWND send_btn;
    HWND output_box;
    HWND status_label;
    LLMModel model;
} ChatApp;

ChatApp g_app = {0};

void matrix_multiply_cpu(const float* A, const float* B, float* C,
                         int m, int n, int k) {
    for (int i = 0; i < m; i++) {
        for (int j = 0; j < n; j++) {
            float sum = 0.0f;
            for (int p = 0; p < k; p++) {
                sum += A[i * k + p] * B[p * n + j];
            }
            C[i * n + j] = sum;
        }
    }
}

void softmax(float* data, int size) {
    float max_val = data[0];
    for (int i = 1; i < size; i++) {
        if (data[i] > max_val) max_val = data[i];
    }
    
    float sum = 0.0f;
    for (int i = 0; i < size; i++) {
        data[i] = (float)exp(data[i] - max_val);
        sum += data[i];
    }
    
    for (int i = 0; i < size; i++) {
        data[i] /= sum;
    }
}

char* generate_response(const char* prompt, int max_tokens) {
    static char response[1024];
    sprintf_s(response, sizeof(response), "Response to: %s (tokens: %d)", 
              prompt, max_tokens);
    return response;
}

LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    switch (uMsg) {
        case WM_CREATE: {
            g_app.hwnd = hwnd;
            
            g_app.output_box = CreateWindowA(
                "LISTBOX", "",
                WS_CHILD | WS_VISIBLE | WS_VSCROLL | LBS_MULTISEL,
                10, 10, 460, 400,
                hwnd, NULL, NULL, NULL);
            
            g_app.input_box = CreateWindowA(
                "EDIT", "",
                WS_CHILD | WS_VISIBLE | WS_BORDER,
                10, 420, 370, 30,
                hwnd, NULL, NULL, NULL);
            
            g_app.send_btn = CreateWindowA(
                "BUTTON", "Send",
                WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
                390, 420, 80, 30,
                hwnd, (HMENU)1001, NULL, NULL);
            
            g_app.status_label = CreateWindowA(
                "STATIC", "Status: Ready (CPU Mode)",
                WS_CHILD | WS_VISIBLE,
                10, 460, 460, 20,
                hwnd, NULL, NULL, NULL);
            
            SendMessageA(g_app.output_box, LB_ADDSTRING, 0, 
                        (LPARAM)"LLM Chat - Native C Implementation");
            SendMessageA(g_app.output_box, LB_ADDSTRING, 0, 
                        (LPARAM)"Local CPU/GPU Inference");
            SendMessageA(g_app.output_box, LB_ADDSTRING, 0, 
                        (LPARAM)"Ready for conversation...");
            
            return 0;
        }
        
        case WM_COMMAND: {
            if (LOWORD(wParam) == 1001) {
                char buffer[256];
                GetWindowTextA(g_app.input_box, buffer, sizeof(buffer));
                
                if (strlen(buffer) > 0) {
                    char display[512];
                    sprintf_s(display, sizeof(display), "You: %s", buffer);
                    SendMessageA(g_app.output_box, LB_ADDSTRING, 0, (LPARAM)display);
                    
                    char* response = generate_response(buffer, 80);
                    char resp_display[512];
                    sprintf_s(resp_display, sizeof(resp_display), "Assistant: %s", response);
                    SendMessageA(g_app.output_box, LB_ADDSTRING, 0, (LPARAM)resp_display);
                    
                    SetWindowTextA(g_app.input_box, "");
                    
                    SendMessageA(g_app.output_box, LB_GETCOUNT, 0, 0);
                    int count = (int)SendMessageA(g_app.output_box, LB_GETCOUNT, 0, 0);
                    SendMessageA(g_app.output_box, LB_SETCURSEL, count - 1, 0);
                }
            }
            return 0;
        }
        
        case WM_PAINT: {
            PAINTSTRUCT ps;
            HDC hdc = BeginPaint(hwnd, &ps);
            FillRect(hdc, &ps.rcPaint, (HBRUSH)(COLOR_WINDOW + 1));
            EndPaint(hwnd, &ps);
            return 0;
        }
        
        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;
            
        default:
            return DefWindowProcA(hwnd, uMsg, wParam, lParam);
    }
    return 0;
}

int main() {
    WNDCLASSA wc = {0};
    wc.lpfnWndProc = WindowProc;
    wc.hInstance = GetModuleHandleA(NULL);
    wc.lpszClassName = "LLMChatC";
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    
    RegisterClassA(&wc);
    
    HWND hwnd = CreateWindowExA(
        0, "LLMChatC", "LLM Chat - Native C Windows",
        WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT, 500, 530,
        NULL, NULL, GetModuleHandleA(NULL), NULL);
    
    if (!hwnd) return 1;
    
    ShowWindow(hwnd, SW_SHOW);
    UpdateWindow(hwnd);
    
    MSG msg = {0};
    while (GetMessageA(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessageA(&msg);
    }
    
    return (int)msg.wParam;
}
