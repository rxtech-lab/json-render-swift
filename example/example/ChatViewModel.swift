import Foundation
import SwiftUI
import SwiftAISDK
import JSONRenderSwift

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let role: Role
    let content: String
    let timestamp: Date
    
    init(id: UUID = UUID(), role: Role, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }

    enum Role: String, Codable {
        case user, assistant, error
    }
}

@Observable
final class ChatViewModel {
    var messages: [ChatMessage] = [] {
        didSet { saveState() }
    }
    var currentSpec: Spec?
    var currentJSON: String = "" {
        didSet { saveState() }
    }
    var isGenerating = false
    var inputText = ""

    @ObservationIgnored
    @AppStorage("providerType") private var providerType: String = AIProviderType.openai.rawValue
    @ObservationIgnored
    @AppStorage("apiEndpoint") private var apiEndpoint: String = ""
    @ObservationIgnored
    @AppStorage("apiKey") private var apiKey: String = ""
    @ObservationIgnored
    @AppStorage("modelName") private var modelName: String = ""
    
    // MARK: - Persistence
    
    private static let stateFileURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("JSONRenderExample", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("chat_state.json")
    }()
    
    init() {
        loadState()
    }
    
    private struct PersistedState: Codable {
        let messages: [ChatMessage]
        let currentJSON: String
    }
    
    private func saveState() {
        let state = PersistedState(messages: messages, currentJSON: currentJSON)
        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: Self.stateFileURL)
        } catch {
            print("[ChatViewModel] Failed to save state: \(error)")
        }
    }
    
    private func loadState() {
        do {
            let data = try Data(contentsOf: Self.stateFileURL)
            let state = try JSONDecoder().decode(PersistedState.self, from: data)
            messages = state.messages
            currentJSON = state.currentJSON
            
            // Restore spec from JSON
            if !currentJSON.isEmpty,
               let jsonData = currentJSON.data(using: .utf8),
               let spec = try? JSONDecoder().decode(Spec.self, from: jsonData) {
                currentSpec = spec
            }
        } catch {
            // No saved state or failed to load - start fresh
            print("[ChatViewModel] No saved state or failed to load: \(error)")
        }
    }

    var isModelConfigured: Bool {
        let provider = AIProviderType(rawValue: providerType) ?? .openai
        switch provider {
        case .openai:
            return !modelName.isEmpty && !apiKey.isEmpty
        case .openaiCompatible:
            return !modelName.isEmpty && !apiEndpoint.isEmpty && !apiKey.isEmpty
        }
    }

    private var service: AIService {
        AIService(
            providerType: AIProviderType(rawValue: providerType) ?? .openai,
            endpoint: apiEndpoint,
            apiKey: apiKey,
            modelName: modelName
        )
    }

    func clearChat() {
        messages = []
        currentSpec = nil
        currentJSON = ""
        inputText = ""
        // Delete saved state
        try? FileManager.default.removeItem(at: Self.stateFileURL)
    }
    
    func send() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        inputText = ""
        messages.append(ChatMessage(role: .user, content: text))
        isGenerating = true
        
        // Keep existing spec for context, but clear for new generation
        let existingJSON = currentJSON
        currentJSON = ""
        currentSpec = nil

        defer { isGenerating = false }

        do {
            let model = try service.makeModel()
            
            // Build prompt with existing UI context if available
            let fullPrompt = buildPrompt(userMessage: text, existingUI: existingJSON)

            let stream = try streamText(
                model: model,
                system: Self.systemPrompt,
                prompt: fullPrompt
            )

            var accumulated = ""
            for try await delta in stream.textStream {
                accumulated += delta

                // Try to parse partial JSON for live preview
                if let jsonData = extractJSON(from: accumulated) {
                    currentJSON = formatJSON(jsonData)
                    if let spec = try? JSONDecoder().decode(Spec.self, from: jsonData) {
                        currentSpec = spec
                    }
                }
            }

            // Final parse
            let finalText = try await stream.text
            if let jsonData = extractJSON(from: finalText) {
                let prettyJSON = formatJSON(jsonData)
                currentJSON = prettyJSON
                let spec = try JSONDecoder().decode(Spec.self, from: jsonData)
                currentSpec = spec
                messages.append(ChatMessage(role: .assistant, content: "UI generated successfully."))
            } else {
                messages.append(ChatMessage(role: .assistant, content: finalText))
            }

        } catch {
            print("[ChatViewModel] Error: \(error)")
            messages.append(ChatMessage(role: .error, content: "Error: \(error.localizedDescription)"))
        }
    }

    private func extractJSON(from text: String) -> Data? {
        // Try to find JSON block in markdown code fence
        if let range = text.range(of: "```json"),
           let endRange = text.range(of: "```", range: range.upperBound..<text.endIndex) {
            let jsonString = String(text[range.upperBound..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            return jsonString.data(using: .utf8)
        }

        // Try to find JSON block in plain code fence
        if let range = text.range(of: "```"),
           let endRange = text.range(of: "```", range: range.upperBound..<text.endIndex) {
            let jsonString = String(text[range.upperBound..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            if jsonString.hasPrefix("{") {
                return jsonString.data(using: .utf8)
            }
        }

        // Try the entire text as JSON
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("{") {
            return trimmed.data(using: .utf8)
        }

        return nil
    }

    private func formatJSON(_ data: Data) -> String {
        if let obj = try? JSONSerialization.jsonObject(with: data),
           let pretty = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys]),
           let str = String(data: pretty, encoding: .utf8) {
            return str
        }
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    private func buildPrompt(userMessage: String, existingUI: String) -> String {
        if existingUI.isEmpty {
            return userMessage
        }
        
        return """
        Current UI JSON:
        ```json
        \(existingUI)
        ```
        
        User request: \(userMessage)
        
        Please modify the existing UI based on the user's request. Output the complete updated JSON.
        """
    }

    // MARK: - System Prompt

    nonisolated static let systemPrompt = """
    You are a UI generator. You output ONLY valid JSON that conforms to the JSONRenderSwift Spec format. Do not include any explanation, markdown, or text outside the JSON.

    \(Spec.schemaDescription)

    Example output:
    {
      "root": "mainStack",
      "state": {"items": [{"name": "Item 1"}, {"name": "Item 2"}], "title": "My List"},
      "elements": {
        "mainStack": {"type": "VStack", "props": {"spacing": 12}, "children": ["header", "itemCard"]},
        "header": {"type": "Text", "props": {"content": {"$state": "/title"}, "font": "title"}},
        "itemCard": {"type": "Card", "props": {"title": {"$item": "name"}}, "repeat": {"statePath": "/items", "key": "name"}}
      }
    }

    Rules:
    1. Output ONLY the JSON object. No markdown fences, no explanation.
    2. Every element must be in the flat "elements" map with a unique string ID.
    3. The "root" field must reference an existing element ID.
    4. Use children arrays to compose layouts.
    5. Use meaningful element IDs (e.g., "loginCard", "emailField").
    6. Always include initial "state" when using $bindState or $state references.
    7. The "repeat" field MUST use "statePath" (not "source" or "data") as the key for the array path.
    8. When given an existing UI JSON to modify, preserve the overall structure and only change what the user requests. Output the complete updated JSON.
    """
}
