#pragma once

#include <windows.h>
#include <string>
#include <vector>

class ChatWindow {
public:
    ChatWindow();
    ~ChatWindow();
    
    bool create();
    void show();
    void run();
    
private:
    HWND hwnd = nullptr;
    HWND edit_input = nullptr;
    HWND button_send = nullptr;
    HWND listbox_messages = nullptr;
    HWND label_status = nullptr;
    
    static LRESULT CALLBACK WindowProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam);
    LRESULT handle_message(UINT msg, WPARAM wparam, LPARAM lparam);
    
    void on_paint();
    void on_send_message();
    void on_create();
};
