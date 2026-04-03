import Foundation
import SwiftAISDK
import AISDKProvider
import OpenAIProvider
import OpenAICompatibleProvider

struct AIService {
    let providerType: AIProviderType
    let endpoint: String
    let apiKey: String
    let modelName: String

    var isConfigured: Bool {
        switch providerType {
        case .openai:
            return !modelName.isEmpty && !apiKey.isEmpty
        case .openaiCompatible:
            return !modelName.isEmpty && !endpoint.isEmpty && !apiKey.isEmpty
        }
    }

    func makeModel() throws -> any LanguageModelV3 {
        guard isConfigured else {
            throw AIServiceError.notConfigured
        }

        switch providerType {
        case .openai:
            let provider = createOpenAIProvider(
                settings: OpenAIProviderSettings(
                    apiKey: apiKey
                )
            )
            return try provider(modelName)

        case .openaiCompatible:
            guard !endpoint.isEmpty else {
                throw AIServiceError.missingEndpoint
            }
            let provider = createOpenAICompatibleProvider(
                settings: OpenAICompatibleProviderSettings(
                    baseURL: endpoint,
                    name: "custom",
                    apiKey: apiKey
                )
            )
            return try provider.languageModel(modelId: modelName)
        }
    }
}

enum AIServiceError: LocalizedError {
    case notConfigured
    case missingEndpoint

    var errorDescription: String? {
        switch self {
        case .notConfigured: "Model is not configured. Open Settings to set up your AI provider."
        case .missingEndpoint: "API endpoint is required for this provider."
        }
    }
}
