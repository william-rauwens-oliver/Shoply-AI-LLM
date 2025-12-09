import SwiftUI

@main
struct LLMChatApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ChatViewModel())
        }
    }
}

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = [
        ChatMessage(role: .system, content: "LLM Chat initialized. Ready for conversation.")
    ]
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var selectedModel: String = "sshleifer/tiny-gpt2"
    @Published var temperature: Float = 0.8
    @Published var systemPrompt: String = "You are a helpful AI assistant."
    @Published var serverStatus: String = "Checking..."
    
    init() {
        checkServerStatus()
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkServerStatus()
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
                let response = try await sendToBackend(message: userMessage)
                messages.append(ChatMessage(role: .assistant, content: response))
            } catch {
                messages.append(ChatMessage(role: .error, content: "Error: \(error.localizedDescription)"))
            }
            isLoading = false
        }
    }
    
    private func sendToBackend(message: String) async throws -> String {
        let url = URL(string: "http://127.0.0.1:7860/api/chat")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = [
            "message": message,
            "system": systemPrompt,
            "temperature": temperature,
            "model": selectedModel
        ] as [String : Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let responseText = json["response"] as? String {
            return responseText
        }
        
        throw URLError(.badServerResponse)
    }
    
    func clearHistory() {
        messages = [ChatMessage(role: .system, content: "LLM Chat initialized.")]
    }
    
    private func checkServerStatus() {
        Task {
            let url = URL(string: "http://127.0.0.1:7860/health")!
            var request = URLRequest(url: url)
            request.timeoutInterval = 2
            
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    await MainActor.run { self.serverStatus = "Online" }
                } else {
                    await MainActor.run { self.serverStatus = "Offline" }
                }
            } catch {
                await MainActor.run { self.serverStatus = "Offline" }
            }
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    enum Role {
        case user, assistant, system, error
    }
    let role: Role
    let content: String
}

struct ContentView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Configuration")
                            .font(.headline)
                        Spacer()
                        Circle()
                            .fill(viewModel.serverStatus == "Online" ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                    }
                    Text(viewModel.serverStatus).font(.caption).foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Label("Model", systemImage: "cube")
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
                    Slider(value: $viewModel.temperature, in: 0.1...2.0, step: 0.1)
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
                
                Spacer()
            }
            .frame(width: 280)
            .padding()
            
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
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.messages) { msg in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(msg.role == .user ? "You" : msg.role == .assistant ? "Assistant" : "System")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                Text(msg.content)
                                    .font(.body)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(msg.role == .user ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        if viewModel.isLoading {
                            HStack {
                                ProgressView().scaleEffect(0.8)
                                Text("Generating...").font(.caption)
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
                        .disabled(viewModel.isLoading || viewModel.serverStatus == "Offline")
                    
                    Button(action: { viewModel.sendMessage() }) {
                        Image(systemName: "paperplane.fill")
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isLoading || viewModel.inputText.isEmpty)
                }
                .padding()
            }
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}
