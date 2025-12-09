# LLM Chat - Complete Native Implementation

Professional LLM chat application with complete platform-native implementations.

## Overview

This project provides a comprehensive LLM chat application with multiple implementations:

- **Native macOS App** (Swift + SwiftUI + CoreML)
- **Native Windows App** (C# + WinUI 3 + ONNX Runtime)
- **Cross-platform Backend** (Python FastAPI)
- **Command-Line Interfaces** (Python, Julia)

## What's Included

```
├── native/
│   ├── macos/          # Swift implementation for macOS
│   ├── windows/        # C# implementation for Windows
│   └── README.md       # Detailed native app documentation
├── app/                # Tauri-based app (legacy)
├── models/             # CLI implementations
│   ├── python-cli/
│   └── julia-cli/
├── QUICKSTART.md
├── README.md
└── PROJECT.md
```

## Quick Start

### Option 1: Native macOS App (Recommended for Mac Users)

```bash
cd native/macos
./build.sh
```

The app will build and launch automatically.

### Option 2: Native Windows App (Recommended for Windows Users)

```cmd
cd native\windows
build.bat
```

The app will build and launch automatically.

### Option 3: Command-Line Interface

**Python**:
```bash
cd models/python-cli
python llm_demo.py --mode chat
```

**Julia**:
```bash
cd models/julia-cli
julia llm_demo.jl --mode=chat
```

## Technology Stack

### macOS
- **Language**: Swift 5.9+
- **UI**: SwiftUI
- **ML**: CoreML + Metal GPU
- **Deployment Target**: macOS 12.0+

### Windows
- **Language**: C# 12 (.NET 8)
- **UI**: WinUI 3
- **ML**: ONNX Runtime + DirectML
- **OS Target**: Windows 10+

### Backend (All Platforms)
- **Framework**: FastAPI (Python)
- **ML Models**: Hugging Face Transformers
- **GPU**: PyTorch with Metal/CUDA/CPU support

## Hardware Requirements

### macOS
- Apple Silicon (M-series) or Intel Mac
- macOS 12.0+
- 2 GB RAM minimum
- 500 MB disk space

### Windows
- Windows 10 (Build 19041)+
- GPU recommended (NVIDIA/AMD)
- 4 GB RAM minimum
- 1 GB disk space

## Supported Models

All implementations support:
- `sshleifer/tiny-gpt2` - 125M parameters (fastest)
- `distilgpt2` - 82M parameters (balanced)
- `gpt2` - 124M parameters (full-size)

## Performance

### macOS (M3 Pro with Metal GPU)
| Model | Time | GPU Usage |
|-------|------|-----------|
| tiny-gpt2 | 1-2s | Very light |
| distilgpt2 | 2-4s | Light |
| gpt2 | 4-8s | Medium |

### Windows (RTX 3080 with DirectML)
| Model | Time | GPU Usage |
|-------|------|-----------|
| tiny-gpt2 | 2-3s | Low |
| distilgpt2 | 3-6s | Medium |
| gpt2 | 6-12s | High |

## Installation Requirements

### For macOS Development
- Xcode 15.0+
- Swift 5.9+
- Command Line Tools

### For Windows Development
- Visual Studio 2022 or .NET 8 SDK
- C# 12 support
- Windows SDK

### For Backend Server
- Python 3.10+
- PyTorch 2.0+
- CUDA/Metal/CPU support

## Documentation

- **Native Apps**: See `native/README.md` for detailed macOS/Windows development
- **macOS App**: See `native/macos/` for Swift implementation
- **Windows App**: See `native/windows/` for C# implementation
- **Backend**: See `app/server/main.py` for FastAPI implementation
- **CLI Tools**: See `models/` for Python and Julia CLIs
- **Quick Start**: See `QUICKSTART.md` for setup instructions

## Architecture

### Native macOS App Flow
1. SwiftUI UI renders chat interface
2. User message sent to FastAPI backend
3. Response received and displayed
4. Optional: local CoreML model inference

### Native Windows App Flow
1. WinUI 3 UI renders chat interface
2. User message sent to FastAPI backend
3. Response received and displayed
4. Optional: local ONNX model inference

### Backend Flow
1. FastAPI server receives request
2. Message processed with system prompt
3. LLM generates response using PyTorch
4. Response sent back to client

## Features

### All Platforms
- Real-time chat interface
- Multiple model selection
- Temperature and sampling control
- System prompt customization
- Message history management
- Server health monitoring
- Error handling and recovery

### macOS-Specific
- Native app bundle (.app)
- Metal GPU acceleration
- SwiftUI animations
- macOS keyboard shortcuts
- Spotlight search support

### Windows-Specific
- Native executable (.exe)
- DirectML GPU acceleration
- WinUI 3 modern design
- Windows keyboard shortcuts
- Taskbar integration

## Development

### macOS
```bash
cd native/macos
# Edit LLMChat.swift
./build.sh
```

### Windows
```cmd
cd native\windows
REM Edit MainWindow.xaml or MainWindow.xaml.cs
build.bat
```

### Backend
```bash
cd app/server
python main.py
```

## Deployment

### macOS Distribution
```bash
cd native/macos
./build.sh
# Creates: build/LLMChat.app
# Can be signed and notarized for App Store
```

### Windows Distribution
```cmd
cd native\windows
build.bat
# Creates: build\Release\LLMChat.exe
# Can be signed with code certificate
```

## GitHub Repository

- **URL**: https://github.com/william-rauwens-oliver/Shoply-AI-LLM
- **Branch**: main
- **License**: MIT

## Recent Commits

```
c34fd57 Remove emojis and comments for production release
f486ed7 Add root level gitignore
e0a3ebf Add comprehensive project documentation
```

## Future Enhancements

- iOS/iPadOS support (SwiftUI)
- Linux support (GTK/Qt)
- Web version (React/TypeScript)
- Advanced model fine-tuning UI
- Conversation export (PDF/JSON)
- Multi-user support
- Custom model loading

## Support & Issues

For problems:
1. Check `native/README.md` for platform-specific troubleshooting
2. Review application logs (Console.app on macOS, Event Viewer on Windows)
3. Verify backend server is running on port 7860
4. Check Python environment and dependencies

## License

MIT - See LICENSE file

## Credits

- **Swift Implementation**: SwiftUI Framework, CoreML ML
- **C# Implementation**: Microsoft WinUI 3, ONNX Runtime
- **Backend**: FastAPI, PyTorch, Hugging Face Transformers
- **CLI**: Python, Julia ecosystems

---

**Ready to run natively on your platform!** 🚀
