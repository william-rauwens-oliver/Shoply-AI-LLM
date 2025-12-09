# Development Guide - Native LLM Chat

Complete guide for developing and building native implementations of LLM Chat.

## Directory Structure

```
project/
├── native/                     # Platform-native implementations
│   ├── macos/                  # Swift/SwiftUI app
│   │   ├── LLMChat.swift       # Main implementation
│   │   ├── project.json        # Project metadata
│   │   ├── build.sh            # Build script
│   │   └── build/              # Build output
│   │
│   ├── windows/                # C#/WinUI 3 app
│   │   ├── MainWindow.xaml     # UI definition
│   │   ├── MainWindow.xaml.cs  # Code-behind
│   │   ├── LLMChat.csproj      # Project file
│   │   ├── build.bat           # Build script
│   │   └── build/              # Build output
│   │
│   └── README.md               # Native app documentation
│
├── app/                        # Backend and legacy app
│   ├── server/                 # FastAPI backend
│   ├── src/                    # React frontend (legacy)
│   └── src-tauri/              # Tauri framework (legacy)
│
├── models/                     # CLI implementations
│   ├── python-cli/
│   └── julia-cli/
│
├── NATIVE_README.md            # Main native app guide
├── project-config.json         # Project configuration
└── DEVELOPMENT.md              # This file
```

## Platform-Specific Development

### macOS Development

#### Environment Setup

```bash
# Install Xcode Command Line Tools
xcode-select --install

# Verify Swift installation
swift --version

# Verify Xcode version
xcode-select -p
```

#### Project Structure
- `LLMChat.swift` - Single-file implementation containing:
  - `LLMChatApp` - App entry point
  - `LLMModel` - CoreML model management
  - `ChatViewModel` - Business logic
  - `ContentView` - Main UI
  - `MessageBubble` - Message display

#### Key Components

**LLMModel** - Handles ML inference:
```swift
let model = LLMModel.shared
try await model.loadModel("LLMModel")
let result = try await model.generateText(prompt: "Hello")
```

**ChatViewModel** - Manages chat state:
```swift
@MainActor class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage]
    @Published var isLoading: Bool
    func sendMessage()
    func clearHistory()
}
```

**ContentView** - UI layer:
```swift
struct ContentView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    var body: some View { ... }
}
```

#### Building
```bash
cd native/macos
chmod +x build.sh
./build.sh
```

#### Development Workflow

1. **Edit Code**:
   ```bash
   vim LLMChat.swift
   ```

2. **Build and Run**:
   ```bash
   ./build.sh
   ```

3. **Debug with Xcode**:
   ```bash
   xcode-select -r /Applications/Xcode.app/Contents/Developer
   open -a Xcode .
   ```

4. **View Logs**:
   ```bash
   log show --last 1h --level debug
   ```

#### Performance Optimization

**Metal GPU Usage**:
```swift
let device = MTLCreateSystemDefaultDevice()
let isMetalAvailable = device != nil
```

**Memory Management**:
- Use `@MainActor` for UI updates
- Dispatch heavy computation to `DispatchQueue`
- Proper resource cleanup in deinit

#### Testing
```bash
# Build with debug symbols
xcodebuild \
    -scheme LLMChat \
    -configuration Debug \
    -enableTestability YES

# Run tests
xcodebuild test
```

---

### Windows Development

#### Environment Setup

**Visual Studio 2022**:
```cmd
# Download and install from:
# https://visualstudio.microsoft.com/downloads/

# Required workloads:
# - .NET desktop development
# - Universal Windows Platform development
```

**Or .NET SDK**:
```cmd
# From https://dotnet.microsoft.com/download

dotnet --version
```

#### Project Structure
- `LLMChat.csproj` - Project configuration
- `MainWindow.xaml` - UI definition (XAML)
- `MainWindow.xaml.cs` - Code-behind (C#)

#### Key Components

**AppViewModel** - MVVM ViewModel:
```csharp
public class AppViewModel : INotifyPropertyChanged {
    public ObservableCollection<ChatMessage> Messages { get; set; }
    public RelayCommand SendMessageCommand { get; }
    private async Task SendMessageToServer(string message)
}
```

**MainWindow.xaml** - UI Definition:
```xaml
<Window x:Class="LLMChat.MainWindow">
    <Grid ColumnDefinitions="280,*">
        <!-- Sidebar -->
        <!-- Chat area -->
    </Grid>
</Window>
```

**MainWindow.xaml.cs** - Event Handlers:
```csharp
public sealed partial class MainWindow : Window {
    private void SendButton_Click(...)
    private void MessageInput_KeyDown(...)
}
```

#### Building
```cmd
cd native\windows
build.bat
```

#### Development Workflow

1. **Open in Visual Studio**:
   ```cmd
   start LLMChat.csproj
   ```

2. **Edit XAML/C#**:
   - Edit `MainWindow.xaml` for UI
   - Edit `MainWindow.xaml.cs` for logic

3. **Build and Run**:
   ```cmd
   build.bat
   REM Or F5 in Visual Studio
   ```

4. **Debug**:
   - Set breakpoints in C# code
   - Use Visual Studio debugger
   - Watch variables in Debug window

5. **View Logs**:
   ```cmd
   eventvwr.msc
   ```

#### Performance Optimization

**DirectML GPU Usage**:
```csharp
var device = new ID3D12Device();
var dmlDevice = DMLCreateDevice(device, ...);
```

**Async Operations**:
```csharp
private async Task SendMessageToServer(string message) {
    var response = await _httpClient.PostAsync(...);
}
```

#### Testing
```cmd
dotnet test LLMChat.csproj
```

---

## Backend Development (Python)

### FastAPI Server

Located in `app/server/main.py`

#### Setup
```bash
cd app/server
python -m venv venv
source venv/bin/activate  # macOS/Linux
venv\Scripts\activate     # Windows
pip install -r requirements.txt
```

#### Running
```bash
python main.py
# Server runs on http://127.0.0.1:7860
```

#### Endpoints

**Health Check**:
```bash
curl http://127.0.0.1:7860/health
```

**Chat Endpoint**:
```bash
curl -X POST http://127.0.0.1:7860/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Hello",
    "model": "sshleifer/tiny-gpt2",
    "temperature": 0.8
  }'
```

#### Modification
- Edit `app/server/main.py`
- Restart server
- Native apps automatically reconnect

---

## CLI Development (Python)

Located in `models/python-cli/llm_demo.py`

### Setup
```bash
cd models/python-cli
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### Running
```bash
# Single prompt
python llm_demo.py --prompt "Hello"

# Chat mode
python llm_demo.py --mode chat

# With options
python llm_demo.py --mode chat --model distilgpt2 --temperature 0.9
```

### Modification
- Edit `llm_demo.py`
- Run with `python llm_demo.py`
- No rebuild needed (Python interpreted)

---

## CLI Development (Julia)

Located in `models/julia-cli/llm_demo.jl`

### Setup
```bash
cd models/julia-cli
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

### Running
```bash
julia llm_demo.jl --mode=chat
```

### Modification
- Edit `llm_demo.jl`
- Run with `julia llm_demo.jl`
- No rebuild needed (Julia JIT compiled)

---

## Common Development Tasks

### Adding a Feature

#### On macOS
1. Edit `native/macos/LLMChat.swift`
2. Add to appropriate struct/class
3. Run `./build.sh`
4. Test in app

#### On Windows
1. Edit `native/windows/MainWindow.xaml` or `.xaml.cs`
2. Add XAML for UI or C# for logic
3. Run `build.bat`
4. Test in app

### Debugging Model Inference

**macOS**:
```swift
print("Prompt: \(prompt)")
print("Model device: \(self.device)")
let result = try await model.generateText(...)
print("Response: \(result)")
```

**Windows**:
```csharp
Debug.WriteLine($"Prompt: {message}");
var response = await SendMessageToServer(message);
Debug.WriteLine($"Response: {response}");
```

### Performance Profiling

**macOS**:
```bash
# Use Instruments (Xcode)
xcode-select -p # To verify path
```

**Windows**:
```cmd
# Use Performance Profiler
dotnet trace collect --process-id [PID]
```

### Building Release Version

**macOS**:
```bash
xcodebuild \
    -scheme LLMChat \
    -configuration Release \
    -arch arm64 \
    -derivedDataPath build/Release
```

**Windows**:
```cmd
dotnet publish LLMChat.csproj ^
    --configuration Release ^
    --runtime win-x64 ^
    --self-contained true
```

---

## Git Workflow

### Committing Changes

```bash
# Pull latest
git pull origin main

# Check status
git status

# Stage changes
git add .

# Commit
git commit -m "Feature: [description]"

# Push
git push origin main
```

### Branch Management

```bash
# Create feature branch
git checkout -b feature/name

# Work on feature
# ... edit files ...

# Commit
git commit -am "Feature description"

# Push to origin
git push origin feature/name

# Create PR on GitHub
```

---

## Troubleshooting

### macOS

**Build fails with "Command not found: xcodebuild"**:
```bash
xcode-select --install
```

**Metal GPU not detected**:
```swift
if let device = MTLCreateSystemDefaultDevice() {
    print("Metal available")
} else {
    print("CPU only")
}
```

**App won't launch**:
```bash
# Check code signature
codesign -vvv build/LLMChat.app

# Check logs
log show --last 10m --level debug
```

### Windows

**Build fails with "dotnet not found"**:
- Download .NET 8 SDK from https://dotnet.microsoft.com/download

**WinUI 3 not recognized**:
```cmd
dotnet workload restore
```

**ONNX Runtime issues**:
```cmd
dotnet package add Microsoft.AI.MachineLearning
```

---

## Performance Tips

### macOS
- Use Metal for GPU acceleration
- Profile with Instruments
- Avoid blocking main thread
- Use async/await for IO

### Windows
- Use DirectML for GPU
- Profile with Performance Profiler
- Async all I/O operations
- Use IAsyncOperation for tasks

### Backend
- Cache loaded models
- Use batch inference when possible
- Monitor memory usage
- Profile with cProfile

---

## Resources

- **Swift**: https://www.swift.org/getting-started/
- **SwiftUI**: https://developer.apple.com/tutorials/swiftui/
- **C#**: https://learn.microsoft.com/en-us/dotnet/csharp/
- **WinUI 3**: https://learn.microsoft.com/en-us/windows/apps/winui/winui3/
- **FastAPI**: https://fastapi.tiangolo.com/
- **PyTorch**: https://pytorch.org/

---

Happy developing! 🚀
