import SwiftUI

enum AIProviderType: String, CaseIterable, Identifiable {
    case openai = "OpenAI"
    case openaiCompatible = "OpenAI Compatible"

    var id: String { rawValue }

    var defaultEndpoint: String {
        switch self {
        case .openai: "https://api.openai.com/v1"
        case .openaiCompatible: ""
        }
    }

    var needsCustomEndpoint: Bool {
        switch self {
        case .openai: false
        case .openaiCompatible: true
        }
    }
}

struct SettingsView: View {
    @AppStorage("providerType") private var providerType: String = AIProviderType.openai.rawValue
    @AppStorage("apiEndpoint") private var apiEndpoint: String = ""
    @AppStorage("apiKey") private var apiKey: String = ""
    @AppStorage("modelName") private var modelName: String = ""

    private var selectedProvider: AIProviderType {
        AIProviderType(rawValue: providerType) ?? .openai
    }

    var body: some View {
        Form {
            Section("Provider") {
                Picker("Provider", selection: $providerType) {
                    ForEach(AIProviderType.allCases) { provider in
                        Text(provider.rawValue).tag(provider.rawValue)
                    }
                }

                if selectedProvider.needsCustomEndpoint {
                    TextField("API Endpoint", text: $apiEndpoint)
                        .textFieldStyle(.roundedBorder)
                } else {
                    LabeledContent("Endpoint") {
                        Text(selectedProvider.defaultEndpoint)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Authentication") {
                SecureField("API Key", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
            }

            Section("Model") {
                TextField("Model Name (e.g. gpt-4o, llama3)", text: $modelName)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 300)
        .onChange(of: providerType) {
            if !selectedProvider.needsCustomEndpoint {
                apiEndpoint = selectedProvider.defaultEndpoint
            }
        }
    }
}
