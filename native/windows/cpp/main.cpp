#include "gui.hpp"
#include "inference_engine.hpp"
#include <iostream>

int main() {
    try {
        ChatWindow window;
        
        if (!window.create()) {
            std::cerr << "Failed to create window" << std::endl;
            return 1;
        }
        
        window.show();
        window.run();
        
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
    
    return 0;
}

#ifdef _WIN32
int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
                   LPSTR lpCmdLine, int nCmdShow) {
    return main();
}
#endif
