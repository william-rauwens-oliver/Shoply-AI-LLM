#include "gui.hpp"
#include "inference_engine.hpp"
#include <sstream>
#include <thread>

static ChatWindow* g_window = nullptr;

ChatWindow::ChatWindow() = default;
ChatWindow::~ChatWindow() {
    if (hwnd) {
        DestroyWindow(hwnd);
    }
}

LRESULT CALLBACK ChatWindow::WindowProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam) {
    ChatWindow* pThis = nullptr;
    
    if (msg == WM_CREATE) {
        CREATESTRUCT* pCreate = reinterpret_cast<CREATESTRUCT*>(lparam);
        pThis = reinterpret_cast<ChatWindow*>(pCreate->lpCreateParams);
        SetWindowLongPtr(hwnd, GWLP_USERDATA, (LONG_PTR)pThis);
    } else {
        pThis = reinterpret_cast<ChatWindow*>(GetWindowLongPtr(hwnd, GWLP_USERDATA));
    }
    
    if (pThis) {
        return pThis->handle_message(msg, wparam, lparam);
    }
    
    return DefWindowProc(hwnd, msg, wparam, lparam);
}

LRESULT ChatWindow::handle_message(UINT msg, WPARAM wparam, LPARAM lparam) {
    switch (msg) {
        case WM_CREATE:
            on_create();
            return 0;
            
        case WM_PAINT:
            on_paint();
            return 0;
            
        case WM_COMMAND:
            if (LOWORD(wparam) == 101) {
                on_send_message();
            }
            return 0;
            
        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;
            
        default:
            return DefWindowProc(hwnd, msg, wparam, lparam);
    }
}

bool ChatWindow::create() {
    const wchar_t CLASS_NAME[] = L"LLMChatWindow";
    
    WNDCLASS wc = {};
    wc.lpfnWndProc = WindowProc;
    wc.hInstance = GetModuleHandle(NULL);
    wc.lpszClassName = CLASS_NAME;
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    
    RegisterClass(&wc);
    
    hwnd = CreateWindowEx(
        0, CLASS_NAME, L"LLM Chat - Native C++ Windows",
        WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT, 1000, 700,
        NULL, NULL, GetModuleHandle(NULL), this);
    
    return hwnd != nullptr;
}

void ChatWindow::on_create() {
    listbox_messages = CreateWindow(
        L"LISTBOX", L"",
        WS_CHILD | WS_VISIBLE | WS_VSCROLL | LBS_MULTISEL,
        10, 10, 970, 550,
        hwnd, nullptr, GetModuleHandle(NULL), NULL);
    
    edit_input = CreateWindow(
        L"EDIT", L"",
        WS_CHILD | WS_VISIBLE | WS_BORDER,
        10, 570, 880, 30,
        hwnd, nullptr, GetModuleHandle(NULL), NULL);
    
    button_send = CreateWindow(
        L"BUTTON", L"Send",
        WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
        900, 570, 80, 30,
        hwnd, (HMENU)101, GetModuleHandle(NULL), NULL);
    
    label_status = CreateWindow(
        L"STATIC", L"Status: Ready",
        WS_CHILD | WS_VISIBLE,
        10, 610, 970, 20,
        hwnd, nullptr, GetModuleHandle(NULL), NULL);
    
    SendMessage(listbox_messages, LB_ADDSTRING, 0, (LPARAM)L"LLM Chat - Native C++ Implementation");
    SendMessage(listbox_messages, LB_ADDSTRING, 0, (LPARAM)L"GPU/CPU Inference Engine");
    SendMessage(listbox_messages, LB_ADDSTRING, 0, (LPARAM)L"Ready for conversation...");
}

void ChatWindow::on_send_message() {
    wchar_t buffer[1024] = {};
    GetWindowText(edit_input, buffer, ARRAYSIZE(buffer));
    
    if (wcslen(buffer) == 0) return;
    
    std::wstring wstr(buffer);
    std::string str(wstr.begin(), wstr.end());
    
    std::wstring display = L"You: " + std::wstring(wstr.begin(), wstr.end());
    SendMessage(listbox_messages, LB_ADDSTRING, 0, (LPARAM)display.c_str());
    
    SetWindowText(edit_input, L"");
    
    SetWindowText(label_status, L"Status: Generating response...");
    
    std::thread([this, str]() {
        LLM::LLMInferenceEngine engine(LLM::LLMInferenceEngine::CPU);
        std::string response = engine.generate(str, 50, 0.8f);
        
        std::wstring wresponse(response.begin(), response.end());
        std::wstring display = L"Assistant: " + wresponse;
        
        PostMessage(hwnd, WM_APP, 0, 0);
        
    }).detach();
}

void ChatWindow::on_paint() {
    PAINTSTRUCT ps;
    HDC hdc = BeginPaint(hwnd, &ps);
    
    FillRect(hdc, &ps.rcPaint, (HBRUSH)(COLOR_WINDOW + 1));
    
    EndPaint(hwnd, &ps);
}

void ChatWindow::show() {
    ShowWindow(hwnd, SW_SHOW);
    UpdateWindow(hwnd);
}

void ChatWindow::run() {
    MSG msg = {};
    while (GetMessage(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
}
