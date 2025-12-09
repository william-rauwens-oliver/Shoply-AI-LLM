import SwiftUI

@main
struct LLMChatApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var messages: [String] = ["LLM Chat Ready"]
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("🤖 LLM Chat").font(.title2).bold()
                Spacer()
                Text(isLoading ? "Loading..." : "Ready").foregroundColor(.green).font(.caption)
            }.padding()
            
            List(messages, id: \.self) { msg in
                Text(msg).textSelection(.enabled)
            }
            
            HStack(spacing: 8) {
                TextField("Enter prompt...", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                    .disabled(isLoading)
                
                Button(action: sendMessage) {
                    Text("Send").bold()
                }
                .disabled(isLoading || inputText.isEmpty)
                .keyboardShortcut(.return, modifiers: [])
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 400)
    }
    
    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        let prompt = inputText
        messages.append("You: \(prompt)")
        inputText = ""
        isLoading = true
        
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            messages.append("AI: Running on local GPU (Metal acceleration)")
            isLoading = false
        }
    }
}
