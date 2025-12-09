import SwiftUI
import CoreML
import Vision
import Metal

@main
struct LLMChatApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ChatViewModel())
        }
    }
}

class LLMModel {
    static let shared = LLMModel()
    
    private let device: MLComputeUnit
    private var model: MLModel?
    private let queue = DispatchQueue(label: "com.llm.inference", qos: .userInitiated)
    
    init() {
        let isMetalAvailable = MTLCreateSystemDefaultDevice() != nil
        self.device = isMetalAvailable ? .all : .cpuOnly
    }
    
    func loadModel(_ modelName: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    let config = MLModelConfiguration()
                    config.computeUnits = self.device
                    
                    guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
                        throw ModelError.modelNotFound
                    }
                    
                    self.model = try MLModel(contentsOf: modelURL, configuration: config)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func generateText(prompt: String, maxTokens: Int = 80, temperature: Float = 0.8) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    guard let model = self.model else {
                        throw ModelError.modelNotLoaded
                    }
                    
                    let input = try self.prepareInput(prompt: prompt)
                    let output = try model.prediction(from: input)
                    let result = try self.extractOutput(output: output, maxTokens: maxTokens)
                    
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func prepareInput(prompt: String) throws -> MLFeatureProvider {
        let textFeature = MLFeatureValue(string: prompt)
        let featureDict: [String: MLFeatureValue] = ["text": textFeature]
        let featureProvider = try MLDictionaryFeatureProvider(dictionary: featureDict)
        return featureProvider
    }
    
    private func extractOutput(output: MLFeatureProvider, maxTokens: Int) throws -> String {
        if let textOutput = output.featureValue(for: "output")?.stringValue {
            return textOutput
        }
        throw ModelError.invalidOutput
    }
}

enum ModelError: LocalizedError {
    case modelNotFound
    case modelNotLoaded
    case invalidOutput
    case inferenceError
    
    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "Model file not found"
        case .modelNotLoaded:
            return "Model not loaded"
        case .invalidOutput:
            return "Invalid model output"
        case .inferenceError:
            return "Inference failed"
        }
    }
}

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var selectedModel: String = "tiny-gpt2"
    @Published var temperature: Float = 0.8
    @Published var systemPrompt: String = "You are a helpful AI assistant."
    @Published var serverStatus: ConnectionStatus = .unknown
    
    private let llmModel = LLMModel.shared
    
    enum ConnectionStatus: String {
        case online = "Online"
        case offline = "Offline"
        case unknown = "Unknown"
    }
    
    init() {
        checkServerConnection()
        Task {
            do {
                try await llmModel.loadModel("LLMModel")
            } catch {
                print("Failed to load model: \(error)")
            }
        }
    }
    
    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let userMessage = inputText
        inputText = ""
        messages.append(ChatMessage(role: .user, content: userMessage))
        isLoading = true
        
        Task {
            do {
                let response = try await llmModel.generateText(
                    prompt: userMessage,
                    temperature: temperature
                )
                messages.append(ChatMessage(role: .assistant, content: response))
            } catch {
                messages.append(ChatMessage(role: .error, content: "Error: \(error.localizedDescription)"))
            }
            isLoading = false
        }
    }
    
    func clearHistory() {
        messages.removeAll()
    }
    
    private func checkServerConnection() {
        let url = URL(string: "http://127.0.0.1:7860/health")!
        var request = URLRequest(url: url)
        request.timeoutInterval = 2
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] _, response, _ in
            let status: ConnectionStatus = (response as? HTTPURLResponse)?.statusCode == 200 ? .online : .offline
            Task { @MainActor in
                self?.serverStatus = status
            }
        }
        task.resume()
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    enum Role {
        case user
        case assistant
        case system
        case error
    }
    let role: Role
    let content: String
}

struct ContentView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @State private var showSettings = false
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Configuration")
                            .font(.headline)
                        Spacer()
                        Circle()
                            .fill(viewModel.serverStatus == .online ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                    }
                    
                    Text(viewModel.serverStatus.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Label("Model", systemImage: "cube")
                        .font(.subheadline)
                    
                    Picker("Model", selection: $viewModel.selectedModel) {
                        Text("tiny-gpt2").tag("tiny-gpt2")
                        Text("distilgpt2").tag("distilgpt2")
                        Text("gpt2").tag("gpt2")
                    }
                    .pickerStyle(.segmented)
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Label("Temperature: \(String(format: "%.2f", viewModel.temperature))", systemImage: "thermometer")
                        .font(.subheadline)
                    
                    Slider(value: $viewModel.temperature, in: 0.1...2.0, step: 0.1)
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Label("System Prompt", systemImage: "text.bubble")
                        .font(.subheadline)
                    
                    TextEditor(text: $viewModel.systemPrompt)
                        .frame(height: 80)
                        .border(Color.gray.opacity(0.3))
                        .cornerRadius(4)
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
                
                Button(action: { viewModel.clearHistory() }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clear History")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
                
                Spacer()
            }
            .frame(width: 280)
            .padding()
            .background(Color(.controlBackgroundColor))
            
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("LLM Chat")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Apple Silicon Optimized")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.controlBackgroundColor))
                .borderBottom(width: 1, color: Color.gray.opacity(0.3))
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                        }
                        
                        if viewModel.isLoading {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Generating...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                }
                
                HStack(spacing: 8) {
                    TextField("Type a message...", text: $viewModel.inputText)
                        .textFieldStyle(.roundedBorder)
                        .disabled(viewModel.isLoading || viewModel.serverStatus == .offline)
                    
                    Button(action: { viewModel.sendMessage() }) {
                        Image(systemName: "paperplane.fill")
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isLoading || viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding()
            }
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var backgroundColor: Color {
        switch message.role {
        case .user:
            return Color.blue.opacity(0.2)
        case .assistant:
            return Color.gray.opacity(0.1)
        case .system:
            return Color.yellow.opacity(0.1)
        case .error:
            return Color.red.opacity(0.1)
        }
    }
    
    var labelText: String {
        switch message.role {
        case .user:
            return "You"
        case .assistant:
            return "Assistant"
        case .system:
            return "System"
        case .error:
            return "Error"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(labelText)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text(message.content)
                .font(.body)
                .lineLimit(nil)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(backgroundColor)
        .cornerRadius(8)
    }
}

extension View {
    func borderBottom(width: CGFloat, color: Color) -> some View {
        VStack(spacing: 0) {
            self
            Divider()
                .frame(height: width)
                .background(color)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ChatViewModel())
}
