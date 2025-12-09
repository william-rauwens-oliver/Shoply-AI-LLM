# Native LLM Chat Applications

Complete platform-native implementations of LLM Chat for macOS and Windows.

## Architecture

### macOS (Swift + SwiftUI)
- **Framework**: SwiftUI
- **ML Runtime**: CoreML with Metal GPU
- **Language**: Swift 5.9+
- **Deployment Target**: macOS 12.0+
- **Architecture**: ARM64 (Apple Silicon), x86_64 (Intel)

**Key Features**:
- Native App Bundle (.app)
- Automatic Metal GPU acceleration
- Core Data for message persistence
- Native macOS keyboard shortcuts
- Spotlight integration support

### Windows (C# + WinUI 3)
- **Framework**: WinUI 3 / Windows App SDK
- **ML Runtime**: ONNX Runtime with DirectML
- **Language**: C# 12 (.NET 8)
- **OS**: Windows 10+
- **Architecture**: x64, Arm64

**Key Features**:
- Native Windows App (.exe)
- DirectML GPU acceleration
- Windows Registry for settings
- Windows shell integration
- Native Windows animations

---

## Building

### macOS Application

**Requirements**:
- Xcode 15.0+
- Swift 5.9+
- macOS 12.0+

**Build**:
```bash
cd native/macos
chmod +x build.sh
./build.sh
```

**Output**: `build/DerivedData/Build/Products/Release/LLMChat.app`

**Manual Build**:
```bash
xcodebuild \
    -scheme LLMChat \
    -configuration Release \
    -arch arm64 \
    -derivedDataPath build/DerivedData \
    build
```

**Run**:
```bash
open build/DerivedData/Build/Products/Release/LLMChat.app
```

### Windows Application

**Requirements**:
- Visual Studio 2022 or .NET 8 SDK
- Windows 10+
- C# 12 support

**Build**:
```cmd
cd native\windows
build.bat
```

**Output**: `build\Release\LLMChat.exe`

**Manual Build**:
```cmd
dotnet publish LLMChat.csproj ^
    --configuration Release ^
    --runtime win-x64 ^
    --output build\Release ^
    --self-contained false
```

**Run**:
```cmd
build\Release\LLMChat.exe
```

---

## Project Structure

```
native/
├── macos/
│   ├── LLMChat.swift         # Main app, views, and logic
│   ├── project.json          # Project metadata
│   ├── build.sh              # Build script
│   └── build/                # Build output
│
└── windows/
    ├── MainWindow.xaml       # UI definition
    ├── MainWindow.xaml.cs    # Code-behind
    ├── LLMChat.csproj        # Project file
    ├── build.bat             # Build script
    └── build/                # Build output
```

---

## Technology Stack

### macOS Stack
| Component | Technology | Version |
|-----------|-----------|---------|
| UI Framework | SwiftUI | Native |
| ML Runtime | CoreML | Native |
| GPU | Metal Performance Shaders | Native |
| Threading | async/await | Swift 5.5+ |
| Persistence | Codable | Swift standard |

### Windows Stack
| Component | Technology | Version |
|-----------|-----------|---------|
| UI Framework | WinUI 3 | 2.8+ |
| ML Runtime | ONNX Runtime | 1.16+ |
| GPU | DirectML | Windows 11+ |
| Framework | .NET | 8.0 |
| MVVM | Community Toolkit | 8.2+ |

---

## Features

### Common Features
- Real-time chat interface
- Model selection (tiny-gpt2, distilgpt2, gpt2)
- Temperature and sampling controls
- System prompt customization
- Message history
- Server health monitoring
- Error handling and recovery

### Platform-Specific Optimizations

**macOS**:
- Metal GPU acceleration for M3 Pro
- Native macOS UI gestures
- Cmd+Q keyboard shortcut
- Application menu integration
- Retina display support

**Windows**:
- DirectML GPU acceleration
- Native Windows keyboard shortcuts
- Dark/Light theme support
- Windows Taskbar integration
- File Save/Open dialogs

---

## GPU Support

### macOS - Metal Performance Shaders
- Automatic M3 Pro detection
- Metal Compute for inference
- GPU memory optimization
- Power management

**Performance**:
```
tiny-gpt2:  1-2 seconds
distilgpt2: 2-4 seconds
gpt2:       4-8 seconds
```

### Windows - DirectML
- Automatic NVIDIA/AMD detection
- DirectML compute backend
- VRAM management
- Mixed precision support

**Performance**:
```
tiny-gpt2:  2-3 seconds (with GPU)
distilgpt2: 3-6 seconds (with GPU)
gpt2:       6-12 seconds (with GPU)
```

---

## Backend Connection

Both native apps connect to the LLM backend server:

**Default**: `http://127.0.0.1:7860`

**Server Endpoints**:
- `GET /health` - Check server status
- `POST /api/chat` - Send message and get response

**Request Format**:
```json
{
  "message": "User input text",
  "system": "System prompt",
  "temperature": 0.8,
  "model": "sshleifer/tiny-gpt2"
}
```

**Response Format**:
```json
{
  "response": "Generated text response"
}
```

---

## Development

### macOS Development

**Hot Reload** (with Xcode):
```bash
xcodebuild \
    -scheme LLMChat \
    -configuration Debug \
    -arch arm64 \
    -derivedDataPath build/DerivedData \
    build
```

**Preview Canvas** (in Xcode):
- Click `Resume` to see live preview
- Edit Swift code and see changes immediately

### Windows Development

**Debug Configuration**:
```bash
dotnet run --configuration Debug --project LLMChat.csproj
```

**Visual Studio Debugger**:
- Set breakpoints in C# code
- Step through execution
- Inspect variables in Debug windows

---

## Deployment

### macOS Distribution

**Create App Bundle**:
```bash
productbuild --component build/LLMChat.app /Applications LLMChat.pkg
```

**Code Signing** (requires Apple Developer ID):
```bash
codesign --deep --force --verify --verbose \
    --sign "Developer ID Application" \
    build/LLMChat.app
```

**Notarization**:
```bash
xcrun altool --notarize-app -f LLMChat.dmg \
    --primary-bundle-id com.williamrauwens.llmchat \
    -u apple-id@example.com -p app-specific-password
```

### Windows Distribution

**Create Installer** (MSIX):
```bash
dotnet publish LLMChat.csproj \
    --configuration Release \
    --runtime win-x64 \
    -p:PublishReadyToRun=true \
    -p:PublishTrimmed=true
```

**Sign Application** (requires code signing certificate):
```cmd
signtool sign /f certificate.pfx /p password /t http://timestamp.server LLMChat.exe
```

---

## Requirements

### macOS
- macOS 12.0 or later
- Xcode 15.0+ (for development)
- Apple Silicon or Intel Mac
- 500 MB free disk space
- Python 3.10+ (for backend server)

### Windows
- Windows 10 (Build 19041) or later
- .NET 8 Runtime
- 2 GB RAM minimum
- GPU (NVIDIA/AMD recommended, CPU fallback)
- Python 3.10+ (for backend server)

---

## Troubleshooting

### macOS

**App won't start**:
```bash
# Check developer certificate
codesign -vvv build/LLMChat.app

# Run from console to see errors
open -a Console
# Then run: open build/LLMChat.app
```

**GPU not detected**:
```bash
# Check Metal support
system_profiler SPDisplaysDataType

# Verify CoreML availability
python3 -c "import coremltools; print('OK')"
```

### Windows

**App crashes on startup**:
```cmd
# Check .NET Runtime
dotnet --info

# View event logs
eventvwr.msc
```

**GPU not detected**:
```cmd
# Check DirectML availability
powershell Get-Command Get-WmiObject | Select-Object *GPU*

# List GPU devices
nvidia-smi  REM for NVIDIA
rocm-smi    REM for AMD
```

---

## License

MIT

## Support

For issues:
1. **macOS**: Run Console.app and check logs
2. **Windows**: Check Event Viewer (eventvwr.msc)
3. Check backend server logs: `app/server/main.py`
